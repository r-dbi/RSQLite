#include "pch.h"
extern "C" {
#include "vendor/sqlite3/sqlite3.h"
int sqlite3_http_stats(sqlite3_int64*, int*, int*);
}

// Retrieve global HTTP VFS stats (best-effort).
[[cpp11::register]]
cpp11::writable::list sqlite_http_stats() {
  sqlite3_int64 bytes = 0;
  int ranges = 0;
  int fulldl = 0;
#ifdef RSQLITE_ENABLE_HTTPVFS
  sqlite3_http_stats(&bytes, &ranges, &fulldl);
#endif
  cpp11::writable::list out;
  out.push_back(cpp11::as_sexp(bytes));        // bytes_fetched
  out.push_back(cpp11::as_sexp(ranges));       // range_requests
  out.push_back(cpp11::as_sexp(fulldl != 0));  // full_download (logical flag)
  out.names() = { "bytes_fetched", "range_requests", "full_download" };
  return out;
}
