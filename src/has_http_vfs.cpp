#include "pch.h"

extern "C" {
#include "vendor/sqlite3/sqlite3.h"
}

// Return true if an HTTP-related VFS has been registered.
[[cpp11::register]]
bool sqlite_has_http_vfs() {
  return sqlite3_vfs_find("http") || sqlite3_vfs_find("httpvfs") || sqlite3_vfs_find("httpfs");
}

// Return true iff package was compiled with HTTP VFS enabled.
// This reflects the presence of the RSQLITE_ENABLE_HTTPVFS macro at build time.
[[cpp11::register]]
bool sqlite_httpvfs_compiled() {
#ifdef RSQLITE_ENABLE_HTTPVFS
  return true;
#else
  return false;
#endif
}
