#define STRICT_R_HEADERS
#define R_NO_REMAP

#include "pch.h"

#ifndef __RSQLITE_TYPES__
#define __RSQLITE_TYPES__

#include <RSQLite.h>

#include "DbConnection.h"
#include "DbResult.h"
#include "SqliteResult.h"

namespace cpp11 {

template <typename T>
using enable_if_dbres_ptr = typename std::enable_if<
    std::is_same<DbResult*, T>::value, T>::type;

template <typename T>
enable_if_dbres_ptr<T> as_cpp(SEXP x) {
  DbResult* result = (DbResult*)(R_ExternalPtrAddr(x));
  if (!result)
    Rcpp::stop("Invalid result set");
  return result;
}

template <typename T>
using enable_if_sqliteres_ptr = typename std::enable_if<
    std::is_same<SqliteResult*, T>::value, T>::type;

template <typename T>
enable_if_sqliteres_ptr<T> as_cpp(SEXP x) {
  SqliteResult* result = (SqliteResult*)(R_ExternalPtrAddr(x));
  if (!result)
    Rcpp::stop("Invalid result set");
  return result;
}

}  // namespace cpp11


#endif
