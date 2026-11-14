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
  // Each element is held in a protected cpp11::sexp while the list is allocated.
  using namespace cpp11::literals;
  return cpp11::writable::list({
    "bytes_fetched"_nm = cpp11::as_sexp(bytes),
    "range_requests"_nm = cpp11::as_sexp(ranges),
    "full_download"_nm = cpp11::as_sexp(fulldl != 0),
  });
}
