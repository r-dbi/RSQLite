#include "pch.h"

#ifndef __RSQLSITE_TYPES__
#define __RSQLSITE_TYPES__

#include <RSQLite.h>

#include "DbConnection.h"
#include "DbResult.h"

namespace Rcpp {

template<>
DbConnection* as(SEXP x);

template<>
DbResult* as(SEXP x);

}

#endif
