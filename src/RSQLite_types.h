#ifndef __RSQLITE_TYPES__
#define __RSQLITE_TYPES__

#include "RSQLite.h"

#include "DbConnection.h"
#include "DbResult.h"
#include "SqliteResult.h"

namespace cpp11 {

// The external pointer of a result owns a shared pointer, so that a lazy
// Arrow stream can keep the result alive after the R object has been cleared.

template <typename T>
using enable_if_dbres_ptr =
  typename std::enable_if<std::is_same<DbResult*, T>::value, T>::type;

template <typename T>
enable_if_dbres_ptr<T> as_cpp(SEXP x) {
  DbResultPtr* result = (DbResultPtr*)(R_ExternalPtrAddr(x));
  if (!result || !result->get()) {
    cpp11::stop("Invalid result set");
  }
  return result->get();
}

template <typename T>
using enable_if_sqliteres_ptr =
  typename std::enable_if<std::is_same<SqliteResult*, T>::value, T>::type;

template <typename T>
enable_if_sqliteres_ptr<T> as_cpp(SEXP x) {
  DbResultPtr* result = (DbResultPtr*)(R_ExternalPtrAddr(x));
  if (!result || !result->get()) {
    cpp11::stop("Invalid result set");
  }
  return static_cast<SqliteResult*>(result->get());
}

}  // namespace cpp11

#endif
