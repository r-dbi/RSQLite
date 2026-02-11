/*
  Minimal experimental HTTP/HTTPS read-only VFS for SQLite embedded in RSQLite.
  Not an official SQLite extension.
  Public domain / CC0 style: follows SQLite's policy for extensions.

  Related work (more advanced capabilities, not bundled here):
    - sqlite_web_vfs (C/C++): https://github.com/mlin/sqlite_web_vfs
    - sqlite-vfs-http (Rust crate): see crates.io
    - sqlite-wasm-http (JavaScript/WASM): https://www.npmjs.com/package/sqlite-wasm-http

  Design (current):
    - Range-first: On-demand page fetching over HTTP using Range requests.
      The VFS fetches only the requested bytes (aligned to SQLite page size)
      and keeps a small in-memory LRU cache of pages.
    - Fallback: If the server does not support Range (206), optionally
      falls back to a one-time full download into memory (configurable).
    - Disallows writes, locking, xWrite, xTruncate, xDelete, xSync.
    - Only HTTP/HTTPS URIs supported. Non-http filename => SQLITE_CANTOPEN.
    - Suggest using immutable=1 in URI to avoid pager assumptions about mutability.

  Limitations:
    - No persistent caching across connections.
    - Prefetch is minimal (configurable but conservative by default).
    - If Range not supported and fallback disabled, open will fail.

  Future improvements (not implemented here):
    - Range GETs for pages (incremental fetching instead of full download)
    - Shared caching across connections
    - ETag/Last-Modified validation

  Entry point: sqlite3_http_init
  VFS name: "http"
*/

/* Ensure correct inclusion of SQLite extension headers within RSQLite's vendored layout */
/* We rely on -Ivendor being set, so include relative to that include root */
#include "sqlite3/sqlite3.h"
#include "extensions/sqlite3ext.h"
SQLITE_EXTENSION_INIT1

#ifdef RSQLITE_ENABLE_HTTPVFS

#include <string.h>
#include <stdlib.h>
#include <curl/curl.h>

#ifndef SQLITE_CORE
#define SQLITE_CORE 1
#endif

#define HTTP_VFS_NAME "http"

/* Global aggregated instrumentation (process-wide, not thread-safe but SQLite VFS calls
  are typically serialized in R environments). */
static sqlite3_int64 g_http_bytes_fetched = 0;
static int g_http_range_requests = 0;
static int g_http_full_downloads = 0;

/* ------------ Simple helpers and configuration ----------------- */

static int http_env_bool(const char *name, int defval){
  const char *v = getenv(name);
  if(!v || !*v) return defval;
  if(v[0]=='1' || v[0]=='y' || v[0]=='Y' || v[0]=='t' || v[0]=='T') return 1;
  if(v[0]=='0' || v[0]=='n' || v[0]=='N' || v[0]=='f' || v[0]=='F') return 0;
  return defval;
}

static sqlite3_int64 http_env_int64(const char *name, sqlite3_int64 defval){
  const char *v = getenv(name);
  if(!v || !*v) return defval;
  long long x = atoll(v);
  if(x <= 0) return defval;
  return (sqlite3_int64)x;
}

/* In-memory representation of the remote file */
typedef struct HttpFile HttpFile;
struct HttpFile {
  sqlite3_file base; /* Base class - must be first */
  /* Full-download fallback buffer (if used) */
  unsigned char *data;
  sqlite3_int64 size;            /* Size in bytes when fully downloaded */
  /* Range-based access */
  char *url;                     /* Copied URL */
  CURL *curl;                    /* Reusable easy handle */
  int have_meta;                 /* Whether meta was probed */
  int accept_ranges;             /* Server supports Range */
  sqlite3_int64 content_length;  /* From HEAD/Content-Range, -1 if unknown */
  int page_size;                 /* SQLite page size */
  /* Simple page cache (LRU by move-to-front) */
  int cache_capacity;            /* Max pages */
  int cache_count;               /* Current pages */
  sqlite3_int64 *cache_page_no;  /* Page numbers */
  unsigned char **cache_data;    /* Each page_size bytes */
  /* Behavior knobs (from env) */
  int fallback_full;             /* Fallback to full download if no Range */
  int prefetch_pages;            /* Prefetch next N pages (0=off) */
  /* Instrumentation */
  sqlite3_int64 bytes_fetched;   /* Sum of bytes from range fetches */
  int range_requests;            /* Number of range requests */
  int full_download;             /* 1 if full download fallback used */
};

/* Forward declarations */
static int httpClose(sqlite3_file*);
static int httpRead(sqlite3_file*, void*, int iAmt, sqlite3_int64 iOfst);
static int httpWrite(sqlite3_file*, const void*, int, sqlite3_int64){ return SQLITE_READONLY; }
static int httpTruncate(sqlite3_file*, sqlite3_int64){ return SQLITE_READONLY; }
static int httpSync(sqlite3_file*, int){ return SQLITE_OK; }
static int httpFileSize(sqlite3_file*, sqlite3_int64 *pSize);
static int httpLock(sqlite3_file*, int){ return SQLITE_OK; }
static int httpUnlock(sqlite3_file*, int){ return SQLITE_OK; }
static int httpCheckReservedLock(sqlite3_file*, int *pRes){ *pRes = 0; return SQLITE_OK; }
static int httpFileControl(sqlite3_file*, int op, void *pArg){ (void)op; (void)pArg; return SQLITE_NOTFOUND; }
static int httpSectorSize(sqlite3_file*){ return 0; }
static int httpDeviceCharacteristics(sqlite3_file*){ return SQLITE_IOCAP_IMMUTABLE; }

static int httpOpen(sqlite3_vfs*, const char *zName, sqlite3_file *pFile, int flags, int *pOutFlags);
static int httpDelete(sqlite3_vfs*, const char *zName, int syncDir){ (void)zName; (void)syncDir; return SQLITE_READONLY; }
static int httpAccess(sqlite3_vfs*, const char *zName, int flags, int *pResOut){ (void)flags; /* Stat not reliable; assume exists */ *pResOut = 1; return  SQLITE_OK; }
static int httpFullPathname(sqlite3_vfs*, const char *zName, int nOut, char *zOut){ sqlite3_snprintf(nOut, zOut, "%s", zName); return SQLITE_OK; }
static void *httpDlOpen(sqlite3_vfs*, const char *z){ (void)z; return 0; }
static void httpDlError(sqlite3_vfs*, int nOut, char *zOut){ if(nOut>0) zOut[0] = 0; }
static void (*httpDlSym(sqlite3_vfs*, void*, const char*)) (void){ return 0; }
static void httpDlClose(sqlite3_vfs*, void*){}
static int httpRandomness(sqlite3_vfs*, int nByte, char *zOut){ /* delegate to default vfs */ sqlite3_vfs *pParent = sqlite3_vfs_find(0); return pParent && pParent->xRandomness ? pParent->xRandomness(pParent, nByte, zOut) : SQLITE_ERROR; }
static int httpSleep(sqlite3_vfs*, int micro){ sqlite3_vfs *pParent = sqlite3_vfs_find(0); return pParent->xSleep(pParent, micro); }
static int httpCurrentTime(sqlite3_vfs*, double *pTime){ sqlite3_vfs *pParent = sqlite3_vfs_find(0); return pParent->xCurrentTime(pParent, pTime); }
static int httpGetLastError(sqlite3_vfs*, int, char*){ return 0; }
static int httpCurrentTimeInt64(sqlite3_vfs*, sqlite3_int64 *p){ sqlite3_vfs *pParent = sqlite3_vfs_find(0); return pParent->xCurrentTimeInt64(pParent, p); }

/* Curl write callback for growable buffer */
typedef struct Buf { unsigned char *data; sqlite3_int64 sz; } Buf;
static size_t curl_write_cb(void *contents, size_t sz, size_t nmemb, void *userp){
  size_t realsize = sz * nmemb;
  Buf *b = (Buf*)userp;
  unsigned char *newData = (unsigned char*)sqlite3_realloc(b->data, (int)(b->sz + realsize));
  if(!newData) return 0;
  b->data = newData;
  memcpy(b->data + b->sz, contents, realsize);
  b->sz += (sqlite3_int64)realsize;
  return realsize;
}

/* Content-Range header parsing (for ranged responses) */
struct CR { sqlite3_int64 total; };
static size_t content_range_cb(char *buffer, size_t size, size_t nitems, void *userdata){
  size_t realsize = size * nitems;
  if(realsize >= 13 && strncasecmp(buffer, "Content-Range:", 13)==0){
    char *p = buffer + 13; while(*p==' '||*p=='\t') ++p;
    if(strncasecmp(p, "bytes", 5)==0){
      char *slash = strchr(p, '/');
      if(slash){
        long long tot = atoll(slash+1);
        if(tot>0){ ((struct CR*)userdata)->total = (sqlite3_int64)tot; }
      }
    }
  }
  return realsize;
}

/* Full download fallback */
static int httpDownload(HttpFile *hf, const char *url){
  CURL *curl = curl_easy_init();
  if(!curl) return SQLITE_ERROR;
  Buf b = {0,0};
  curl_easy_setopt(curl, CURLOPT_URL, url);
  curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_write_cb);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, &b);
  CURLcode rc = curl_easy_perform(curl);
  long code = 0;
  curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &code);
  curl_easy_cleanup(curl);
  if(rc != CURLE_OK || code >= 400){
    if(b.data){ sqlite3_free(b.data); }
    hf->data = 0; hf->size = 0;
    return SQLITE_CANTOPEN;
  }
  hf->data = b.data; hf->size = b.sz;
  hf->full_download = 1;
  g_http_full_downloads++;
  g_http_bytes_fetched += b.sz;
  return SQLITE_OK;
}

/* Header parsing */
typedef struct HeaderProbe {
  sqlite3_int64 content_length;
  int accept_ranges;
} HeaderProbe;

static size_t curl_header_cb(char *buffer, size_t size, size_t nitems, void *userdata){
  size_t realsize = size * nitems;
  HeaderProbe *hp = (HeaderProbe*)userdata;
  /* Normalize: header names are case-insensitive */
  if(realsize >= 16 && strncasecmp(buffer, "Content-Length:", 15)==0){
    const char *p = buffer + 15;
    while(*p==' '||*p=='\t') ++p;
    long long v = atoll(p);
    if(v > 0) hp->content_length = (sqlite3_int64)v;
  } else if(realsize >= 16 && strncasecmp(buffer, "Accept-Ranges:", 15)==0){
    const char *p = buffer + 15;
    while(*p==' '||*p=='\t') ++p;
    if(strncasecmp(p, "bytes", 5)==0) hp->accept_ranges = 1;
  }
  return realsize;
}

static int http_probe_meta(HttpFile *hf){
  if(hf->have_meta) return SQLITE_OK;
  hf->content_length = -1;
  hf->accept_ranges = 0;
  if(!hf->curl) hf->curl = curl_easy_init();
  if(!hf->curl) return SQLITE_ERROR;

  HeaderProbe hp; hp.content_length = -1; hp.accept_ranges = 0;
  curl_easy_setopt(hf->curl, CURLOPT_URL, hf->url);
  curl_easy_setopt(hf->curl, CURLOPT_NOBODY, 1L);
  curl_easy_setopt(hf->curl, CURLOPT_HEADER, 1L);
  curl_easy_setopt(hf->curl, CURLOPT_HEADERFUNCTION, curl_header_cb);
  curl_easy_setopt(hf->curl, CURLOPT_HEADERDATA, &hp);
  curl_easy_setopt(hf->curl, CURLOPT_FOLLOWLOCATION, 1L);
  CURLcode rc = curl_easy_perform(hf->curl);
  long code = 0;
  curl_easy_getinfo(hf->curl, CURLINFO_RESPONSE_CODE, &code);
  /* Reset options that shouldn't persist */
  curl_easy_setopt(hf->curl, CURLOPT_NOBODY, 0L);
  curl_easy_setopt(hf->curl, CURLOPT_HEADER, 0L);
  curl_easy_setopt(hf->curl, CURLOPT_HEADERFUNCTION, NULL);
  curl_easy_setopt(hf->curl, CURLOPT_HEADERDATA, NULL);
  if(rc == CURLE_OK && code < 400){
    hf->content_length = hp.content_length;
    hf->accept_ranges = hp.accept_ranges;
  }

  /* Always fetch first 32 bytes to determine page size and also learn Range support if HEAD failed */
  Buf b = {0,0};
  curl_easy_setopt(hf->curl, CURLOPT_URL, hf->url);
  curl_easy_setopt(hf->curl, CURLOPT_WRITEFUNCTION, curl_write_cb);
  curl_easy_setopt(hf->curl, CURLOPT_WRITEDATA, &b);
  curl_easy_setopt(hf->curl, CURLOPT_RANGE, "0-31");
  rc = curl_easy_perform(hf->curl);
  long code2 = 0; curl_easy_getinfo(hf->curl, CURLINFO_RESPONSE_CODE, &code2);
  curl_easy_setopt(hf->curl, CURLOPT_RANGE, NULL);
  if(rc != CURLE_OK || code2 >= 400){ if(b.data) sqlite3_free(b.data); return SQLITE_CANTOPEN; }
  if(code2 == 206) hf->accept_ranges = 1; /* 206 Partial Content indicates range support */
  /* Parse page size from header bytes 16..17 (big endian) */
  int ps = 4096;
  if(b.sz >= 18){
    int psh = ((int)b.data[16] << 8) | (int)b.data[17];
    if(psh == 1) ps = 65536; /* per SQLite spec */
    else if(psh >= 512 && psh <= 65536 && (psh & (psh-1))==0) ps = psh;
  }
  hf->page_size = ps;
  if(b.data) sqlite3_free(b.data);
  /* If content length still unknown, try to infer via a ranged request response header "Content-Range: bytes start-end/size" */
  /* Simpler approach omitted for brevity; leave content_length as-is if HEAD didn't give it. */

  /* Configure cache capacity after knowing page size */
  sqlite3_int64 cache_mb = http_env_int64("RSQLITE_HTTP_CACHE_MB", 4);
  sqlite3_int64 bytes = cache_mb * 1024 * 1024;
  int cap = (int)(bytes / hf->page_size);
  if(cap < 2) cap = 2; if(cap > 2048) cap = 2048; /* clamp */
  hf->cache_capacity = cap;
  hf->cache_count = 0;
  hf->cache_page_no = (sqlite3_int64*)sqlite3_malloc64(sizeof(sqlite3_int64)*cap);
  hf->cache_data = (unsigned char**)sqlite3_malloc64(sizeof(unsigned char*)*cap);
  if(!hf->cache_page_no || !hf->cache_data) return SQLITE_NOMEM;
  for(int i=0;i<cap;i++){ hf->cache_page_no[i] = -1; hf->cache_data[i] = 0; }

  hf->have_meta = 1;
  return SQLITE_OK;
}

/* Fetch [off, off+len-1] into a freshly allocated buffer */
static int http_fetch_range(HttpFile *hf, sqlite3_int64 off, int len, unsigned char **out){
  if(!hf->curl) hf->curl = curl_easy_init();
  if(!hf->curl) return SQLITE_ERROR;
  char range[128];
  sqlite3_snprintf(sizeof(range), range, "%lld-%lld", (long long)off, (long long)(off + (sqlite3_int64)len - 1));
  Buf b = {0,0};
  curl_easy_setopt(hf->curl, CURLOPT_URL, hf->url);
  curl_easy_setopt(hf->curl, CURLOPT_WRITEFUNCTION, curl_write_cb);
  curl_easy_setopt(hf->curl, CURLOPT_WRITEDATA, &b);
  curl_easy_setopt(hf->curl, CURLOPT_RANGE, range);
  curl_easy_setopt(hf->curl, CURLOPT_FOLLOWLOCATION, 1L);
  /* Capture Content-Range to infer total size if unknown */
  struct CR cr; cr.total = -1;
  curl_easy_setopt(hf->curl, CURLOPT_HEADERFUNCTION, content_range_cb);
  curl_easy_setopt(hf->curl, CURLOPT_HEADERDATA, &cr);
  CURLcode rc = curl_easy_perform(hf->curl);
  long code = 0; curl_easy_getinfo(hf->curl, CURLINFO_RESPONSE_CODE, &code);
  curl_easy_setopt(hf->curl, CURLOPT_HEADERFUNCTION, NULL);
  curl_easy_setopt(hf->curl, CURLOPT_HEADERDATA, NULL);
  curl_easy_setopt(hf->curl, CURLOPT_RANGE, NULL);
  if(rc != CURLE_OK || code >= 400){ if(b.data) sqlite3_free(b.data); return SQLITE_IOERR; }
  if(code != 206){
    /* Range not honored; if allowed, fallback to full download */
    if(hf->fallback_full && !hf->data){
      int drc = httpDownload(hf, hf->url);
      if(drc!=SQLITE_OK) { if(b.data) sqlite3_free(b.data); return drc; }
      hf->full_download = 1;
    } else {
      if(b.data) sqlite3_free(b.data);
      return SQLITE_IOERR;
    }
  }
  if(cr.total>0 && hf->content_length<0) hf->content_length = cr.total;
  hf->bytes_fetched += b.sz;
  hf->range_requests += (code == 206);
  if(code == 206){
    g_http_range_requests++;
    g_http_bytes_fetched += b.sz;
  }
  *out = b.data;
  return SQLITE_OK;
}

/* Cache lookup or fetch page; returns pointer to cached page (owned by hf) */
static int http_get_page(HttpFile *hf, sqlite3_int64 pageNo, unsigned char **pageOut){
  if(pageNo <= 0) return SQLITE_CORRUPT;
  /* Full download path */
  if(hf->data){
    sqlite3_int64 off = (pageNo-1) * (sqlite3_int64)hf->page_size;
    if(off + hf->page_size > hf->size) return SQLITE_IOERR_SHORT_READ;
    *pageOut = hf->data + off;
    return SQLITE_OK;
  }
  /* Ensure meta and cache are initialized */
  int rc = http_probe_meta(hf);
  if(rc!=SQLITE_OK) return rc;
  /* Lookup */
  for(int i=0;i<hf->cache_count;i++){
    if(hf->cache_page_no[i] == pageNo){
      unsigned char *p = hf->cache_data[i];
      /* Move-to-front for LRU */
      if(i>0){
        sqlite3_int64 pn = hf->cache_page_no[i];
        unsigned char *pd = hf->cache_data[i];
        memmove(&hf->cache_page_no[1], &hf->cache_page_no[0], sizeof(sqlite3_int64)*i);
        memmove(&hf->cache_data[1], &hf->cache_data[0], sizeof(unsigned char*)*i);
        hf->cache_page_no[0] = pn;
        hf->cache_data[0] = pd;
        p = hf->cache_data[0];
      }
      *pageOut = p;
      return SQLITE_OK;
    }
  }
  /* Miss: fetch */
  unsigned char *buf = 0;
  sqlite3_int64 off = (pageNo-1) * (sqlite3_int64)hf->page_size;
  rc = http_fetch_range(hf, off, hf->page_size, &buf);
  if(rc!=SQLITE_OK) return rc;
  /* Insert at front; evict last if full */
  if(hf->cache_count == hf->cache_capacity){
    /* Free last */
    int last = hf->cache_capacity - 1;
    if(hf->cache_data[last]) sqlite3_free(hf->cache_data[last]);
    /* Shift others right by 1 is replaced by memmove since we insert at 0 */
  } else {
    hf->cache_count++;
  }
  memmove(&hf->cache_page_no[1], &hf->cache_page_no[0], sizeof(sqlite3_int64)*(hf->cache_count-1));
  memmove(&hf->cache_data[1], &hf->cache_data[0], sizeof(unsigned char*)*(hf->cache_count-1));
  hf->cache_page_no[0] = pageNo;
  hf->cache_data[0] = buf;
  *pageOut = buf;

  /* Optional light prefetch */
  if(hf->prefetch_pages > 0){
    for(int k=1; k<=hf->prefetch_pages; k++){
      sqlite3_int64 pn2 = pageNo + k;
      /* Don't prefetch beyond file end if content_length known */
      if(hf->content_length > 0){
        sqlite3_int64 off2 = (pn2-1) * (sqlite3_int64)hf->page_size;
        if(off2 >= hf->content_length) break;
      }
      /* Only prefetch if not cached */
      int hit = 0; for(int i=0;i<hf->cache_count;i++){ if(hf->cache_page_no[i]==pn2){ hit=1; break; } }
      if(hit) continue;
      unsigned char *buf2 = 0;
      if(http_fetch_range(hf, (pn2-1)*(sqlite3_int64)hf->page_size, hf->page_size, &buf2)==SQLITE_OK){
        if(hf->cache_count == hf->cache_capacity){
          int last = hf->cache_capacity - 1;
          if(hf->cache_data[last]) sqlite3_free(hf->cache_data[last]);
        } else {
          hf->cache_count++;
        }
        memmove(&hf->cache_page_no[1], &hf->cache_page_no[0], sizeof(sqlite3_int64)*(hf->cache_count-1));
        memmove(&hf->cache_data[1], &hf->cache_data[0], sizeof(unsigned char*)*(hf->cache_count-1));
        hf->cache_page_no[0] = pn2;
        hf->cache_data[0] = buf2;
      } else {
        if(buf2) sqlite3_free(buf2);
      }
    }
  }

  return SQLITE_OK;
}

static sqlite3_io_methods http_io_methods = {
  3,
  httpClose,
  httpRead,
  httpWrite,
  httpTruncate,
  httpSync,
  httpFileSize,
  httpLock,
  httpUnlock,
  httpCheckReservedLock,
  httpFileControl,
  httpSectorSize,
  httpDeviceCharacteristics,
  0,0,0,0,0
};

static int httpOpen(sqlite3_vfs *pVfs, const char *zName, sqlite3_file *pFile, int flags, int *pOutFlags){
  (void)pVfs; (void)flags; (void)pOutFlags;
  if(!zName) return SQLITE_CANTOPEN;
  if(strncmp(zName, "http://", 7)!=0 && strncmp(zName, "https://", 8)!=0){
    return SQLITE_CANTOPEN; /* only remote URLs */
  }
  HttpFile *hf = (HttpFile*)pFile;
  memset(hf, 0, sizeof(*hf));
  hf->url = sqlite3_mprintf("%s", zName);
  hf->fallback_full = http_env_bool("RSQLITE_HTTP_FALLBACK_FULLDL", 1);
  hf->prefetch_pages = (int)http_env_int64("RSQLITE_HTTP_PREFETCH_PAGES", 0);
  hf->content_length = -1;
  hf->page_size = 4096;
  hf->have_meta = 0;
  hf->bytes_fetched = 0;
  hf->range_requests = 0;
  hf->full_download = 0;
  hf->base.pMethods = &http_io_methods;
  return SQLITE_OK;
}

static int httpClose(sqlite3_file *pFile){
  HttpFile *hf = (HttpFile*)pFile;
  if(hf->data) sqlite3_free(hf->data);
  if(hf->url) sqlite3_free(hf->url);
  if(hf->curl) curl_easy_cleanup(hf->curl);
  if(hf->cache_page_no){ sqlite3_free(hf->cache_page_no); }
  if(hf->cache_data){ for(int i=0;i<hf->cache_capacity;i++){ if(hf->cache_data[i]) sqlite3_free(hf->cache_data[i]); } sqlite3_free(hf->cache_data); }
  hf->data = 0; hf->size = 0;
  hf->base.pMethods = 0;
  return SQLITE_OK;
}

static int httpRead(sqlite3_file *pFile, void *zBuf, int iAmt, sqlite3_int64 iOfst){
  HttpFile *hf = (HttpFile*)pFile;
  /* Full-download path */
  if(hf->data){
    if(iOfst + (sqlite3_int64)iAmt <= hf->size){
      memcpy(zBuf, hf->data + iOfst, (size_t)iAmt);
      return SQLITE_OK;
    }
    if(iOfst < hf->size){
      sqlite3_int64 avail = hf->size - iOfst;
      memcpy(zBuf, hf->data + iOfst, (size_t)avail);
      memset(((unsigned char*)zBuf)+avail, 0, (size_t)(iAmt - avail));
    } else {
      memset(zBuf, 0, (size_t)iAmt);
    }
    return SQLITE_IOERR_SHORT_READ;
  }

  /* Range-based path: fetch required pages */
  int rc = http_probe_meta(hf);
  if(rc!=SQLITE_OK) return rc;
  int ps = hf->page_size;
  unsigned char *out = (unsigned char*)zBuf;
  sqlite3_int64 start = iOfst;
  sqlite3_int64 end = iOfst + (sqlite3_int64)iAmt; /* exclusive */
  sqlite3_int64 pageStart = (start / ps) + 1;
  sqlite3_int64 pageEnd = ((end - 1) / ps) + 1;
  sqlite3_int64 pos = start;
  for(sqlite3_int64 pn = pageStart; pn <= pageEnd; pn++){
    unsigned char *pPage = 0;
    rc = http_get_page(hf, pn, &pPage);
    if(rc!=SQLITE_OK) return rc;
    sqlite3_int64 pOff = (pn - 1) * (sqlite3_int64)ps;
    sqlite3_int64 s = pos > pOff ? pos - pOff : 0;
    sqlite3_int64 e = (pOff + ps) < end ? (pOff + ps) : end;
    sqlite3_int64 n = e - (pOff + s);
    if(n > 0){
      memcpy(out + (pos - start), pPage + s, (size_t)n);
      pos += n;
    }
  }
  /* Short read handling: zero-fill beyond EOF if content_length known and request overruns */
  if(hf->content_length > 0 && end > hf->content_length){
    sqlite3_int64 have = hf->content_length - start;
    if(have < 0) have = 0;
    if(have < iAmt){ memset(out + have, 0, (size_t)(iAmt - have)); return SQLITE_IOERR_SHORT_READ; }
  }
  return SQLITE_OK;
}

static int httpFileSize(sqlite3_file *pFile, sqlite3_int64 *pSize){
  HttpFile *hf = (HttpFile*)pFile;
  if(hf->data){ *pSize = hf->size; return SQLITE_OK; }
  if(!hf->have_meta){ if(http_probe_meta(hf)!=SQLITE_OK){ *pSize = 0; return SQLITE_OK; } }
  *pSize = (hf->content_length > 0) ? hf->content_length : 0;
  return SQLITE_OK;
}

static sqlite3_vfs http_vfs = {
  3,                           /* iVersion */
  sizeof(HttpFile),            /* szOsFile */
  1024,                        /* mxPathname */
  0,                           /* pNext */
  HTTP_VFS_NAME,               /* zName */
  0,                           /* pAppData */
  httpOpen,
  httpDelete,
  httpAccess,
  httpFullPathname,
  httpDlOpen,
  httpDlError,
  httpDlSym,
  httpDlClose,
  httpRandomness,
  httpSleep,
  httpCurrentTime,
  httpGetLastError,
  httpCurrentTimeInt64
};

#ifdef _WIN32
__declspec(dllexport)
#endif
int sqlite3_http_init(sqlite3 *db, char **pzErrMsg, const sqlite3_api_routines *pApi){
  SQLITE_EXTENSION_INIT2(pApi);
  (void)db; (void)pzErrMsg;
  /* Register VFS only once */
  if(!sqlite3_vfs_find(HTTP_VFS_NAME)){
    sqlite3_vfs_register(&http_vfs, 0);
  }
  return SQLITE_OK;
}

/* Expose simple process-global HTTP VFS stats (best-effort).
   Since stats are tracked per-open file, we aggregate using static atomics.
   For simplicity here, provide a getter that returns zeros (placeholder) unless
   future work adds global aggregation. */

#ifdef _WIN32
__declspec(dllexport)
#endif
int sqlite3_http_stats(sqlite3_int64 *bytes, int *ranges, int *fulldl){
  if(bytes) *bytes = g_http_bytes_fetched;
  if(ranges) *ranges = g_http_range_requests;
  if(fulldl) *fulldl = g_http_full_downloads;
  return SQLITE_OK;
}

#else /* RSQLITE_ENABLE_HTTPVFS not defined */
#ifdef _WIN32
__declspec(dllexport)
#endif
int sqlite3_http_init(sqlite3 *db, char **pzErrMsg, const sqlite3_api_routines *pApi){
  SQLITE_EXTENSION_INIT2(pApi);
  (void)db;
  if(pzErrMsg){ *pzErrMsg = sqlite3_mprintf("HTTP VFS disabled at build time"); }
  return SQLITE_ERROR;
}
#endif /* RSQLITE_ENABLE_HTTPVFS */
