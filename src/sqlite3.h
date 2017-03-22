#ifndef __RSQLITE_SQLITE_H
#define __RSQLITE_SQLITE_H

typedef struct _compound_int64_t {
  uint32_t data[2];
} compound_int64_t;

// static assert
typedef int sizeof_compound_int64_t_is_8[sizeof(compound_int64_t) == 8 ? 1 : -1];

// If you see "error: expected initializer before ‘sqlite_uint64’",
// please patch sqlite3.h by running (from the root directory):
//
// patch -p1 < src-raw/sqlite3.patch

#define SQLITE_INT64_TYPE compound_int64_t
#define SQLITE_UINT64_TYPE compound_int64_t

#include "vendor/sqlite3/sqlite3.h"

#endif // #ifndef __RSQLITE_SQLITE_H
