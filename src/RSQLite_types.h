#include "pch.h"

#ifndef __RSQLITE_TYPES__
#define __RSQLITE_TYPES__

#include <RSQLite.h>

#include "DbConnection.h"
#include "DbResult.h"
#include "SqliteResult.h"

namespace Rcpp {

template<>
DbConnection* as(SEXP x);

template<>
DbResult* as(SEXP x);

template<>
SqliteResult* as(SEXP x);

}

#endif
