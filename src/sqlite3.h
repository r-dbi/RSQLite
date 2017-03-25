#ifndef __RSQLITE_SQLITE_H
#define __RSQLITE_SQLITE_H

#include <boost/cstdint.hpp>

// If you see "error: expected initializer before ‘sqlite_uint64’",
// please patch sqlite3.h by running (from the root directory):
//
// patch -p1 < src-raw/sqlite3.patch

#define SQLITE_INT64_TYPE int64_t
#define SQLITE_UINT64_TYPE uint64_t

#include "vendor/sqlite3/sqlite3.h"

#endif // #ifndef __RSQLITE_SQLITE_H
