#include "pch.h"
#include "SqliteParamSource.h"
#include "integer64.h"
#include <stdexcept>

SqliteParamSource::~SqliteParamSource() {}

// SqliteListParamSource ///////////////////////////////////////////////////////

SqliteListParamSource::SqliteListParamSource(const cpp11::list& params_)
    : params(params_), i(0), n(0) {
  if (params.size() > 0) {
    n = Rf_xlength(params[0]);
  }
}

bool SqliteListParamSource::bind_next_row(sqlite3_stmt* stmt) {
  if (i >= n) {
    return false;
  }

  sqlite3_reset(stmt);
  sqlite3_clear_bindings(stmt);

  for (R_xlen_t j = 0; j < params.size(); ++j) {
    // sqlite parameters are 1-indexed
    bind_parameter(stmt, (int)j + 1, params[j]);
  }

  ++i;
  return true;
}

void SqliteListParamSource::bind_parameter(
  sqlite3_stmt* stmt,
  int pos,
  SEXP value_
) const {
  if (TYPEOF(value_) == LGLSXP) {
    int value = LOGICAL(value_)[i];
    if (value == NA_LOGICAL) {
      sqlite3_bind_null(stmt, pos);
    } else {
      sqlite3_bind_int(stmt, pos, value);
    }
  } else if (TYPEOF(value_) == INT64SXP && Rf_inherits(value_, "integer64")) {
    int64_t value = INTEGER64(value_)[i];
    if (value == NA_INTEGER64) {
      sqlite3_bind_null(stmt, pos);
    } else {
      sqlite3_bind_int64(stmt, pos, value);
    }
  } else if (TYPEOF(value_) == INTSXP) {
    int value = INTEGER(value_)[i];
    if (value == NA_INTEGER) {
      sqlite3_bind_null(stmt, pos);
    } else {
      sqlite3_bind_int(stmt, pos, value);
    }
  } else if (TYPEOF(value_) == REALSXP) {
    double value = REAL(value_)[i];
    if (value == NA_REAL) {
      sqlite3_bind_null(stmt, pos);
    } else {
      sqlite3_bind_double(stmt, pos, value);
    }
  } else if (TYPEOF(value_) == STRSXP) {
    SEXP value = STRING_ELT(value_, i);
    if (value == NA_STRING) {
      sqlite3_bind_null(stmt, pos);
    } else {
      sqlite3_bind_text(stmt, pos, CHAR(value), -1, SQLITE_TRANSIENT);
    }
  } else if (TYPEOF(value_) == VECSXP) {
    SEXP value = VECTOR_ELT(value_, i);
    if (TYPEOF(value) == NILSXP) {
      sqlite3_bind_null(stmt, pos);
    } else if (TYPEOF(value) == RAWSXP) {
      sqlite3_bind_blob(
        stmt,
        pos,
        RAW(value),
        Rf_length(value),
        SQLITE_TRANSIENT
      );
    } else {
      throw std::runtime_error("Can only bind lists of raw vectors (or NULL)");
    }
  } else {
    throw std::runtime_error(
      std::string("Don't know how to handle parameter of type ") +
      Rf_type2char(TYPEOF(value_)) + "."
    );
  }
}
