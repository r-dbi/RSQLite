#include <RSQLite.h>
#include "SqliteDataFrame.h"
#include "SqliteUtils.h"
#include "affinity.h"


SqliteDataFrame::SqliteDataFrame(sqlite3_stmt* stmt_, std::vector<std::string> names_, const int n_max_,
                                 const std::vector<SEXPTYPE>& types_)
  : stmt(stmt_),
    n_max(n_max_),
    i(0),
    n(init_n()),
    out(dfCreate(names_, n)),
    types(types_)
{
}

int SqliteDataFrame::init_n() const {
  if (n_max >= 0)
    return n_max;

  return 100;
}

bool SqliteDataFrame::set_col_values() {
  if (i >= n) {
    if (n_max >= 0)
      return false;

    n *= 2;
    out = dfResize(out, n);
  }

  for (int j = 0; j < out.length(); ++j) {
    RObject col = out[j];
    set_col_value(col, j);
    out[j] = col;
  }

  return true;
}

void SqliteDataFrame::advance() {
  ++i;

  if (i % 1000 == 0)
    checkUserInterrupt();
}

List SqliteDataFrame::get_data(std::vector<SEXPTYPE>& types_) {
  // Trim back to what we actually used
  finalize_cols();

  types_ = this->types;
  return out;
}

void SqliteDataFrame::finalize_cols() {
  if (i < n) {
    out = dfResize(out, i);
    n = i;
  }

  alloc_missing_cols();
}

void SqliteDataFrame::alloc_missing_cols() {
  // Create data for columns where all values were NULL (or for all columns
  // in the case of a 0-row data frame)
  for (int j = 0; j < out.length(); ++j) {
    if (types[j] == NILSXP) {
      types[j] =
        decltype_to_sexptype(sqlite3_column_decltype(stmt, j));
      LOG_VERBOSE << j << ": " << types[j];
      out[j] = alloc_col(types[j]);
    }
  }
}

void SqliteDataFrame::set_col_value(RObject& col, const int j) {
  // col needs to be PROTECTed because it can be allocated
  // just before a RAW vector that holds BLOB data is (#192).
  // The easiest way to protect is to make it an RObject.

  SEXPTYPE type = types[j];
  int column_type = sqlite3_column_type(stmt, j);

  LOG_VERBOSE << "column_type: " << column_type;
  LOG_VERBOSE << "type: " << type;

  if (type == NILSXP) {
    LOG_VERBOSE << "datatype_to_sexptype\n";
    type = datatype_to_sexptype(column_type);
    LOG_VERBOSE << "type: " << type;
  }

  if (Rf_isNull(col)) {
    if (type == NILSXP)
      return;
    else {
      col = alloc_col(type);
      types[j] = type;
    }
  }

  if (column_type == SQLITE_NULL) {
    fill_default_col_value(col);
  }
  else {
    fill_col_value(col, j);
  }
  return;
}

SEXP SqliteDataFrame::alloc_col(const SEXPTYPE type) {
  SEXP col = Rf_allocVector(type, n);
  PROTECT(col);
  for (int i_ = 0; i_ < i; i_++) {
    fill_default_col_value(col, i_);
  }
  UNPROTECT(1);
  return col;
}

void SqliteDataFrame::fill_default_col_value(const SEXP col) {
  fill_default_col_value(col, i);
}

void SqliteDataFrame::fill_default_col_value(const SEXP col, const int i_) {
  switch (TYPEOF(col)) {
  case LGLSXP:
    LOGICAL(col)[i_] = NA_LOGICAL;
    break;
  case INTSXP:
    INTEGER(col)[i_] = NA_INTEGER;
    break;
  case REALSXP:
    REAL(col)[i_] = NA_REAL;
    break;
  case STRSXP:
    SET_STRING_ELT(col, i_, NA_STRING);
    break;
  case VECSXP:
    SET_VECTOR_ELT(col, i_, R_NilValue);
    break;
  }
}

void SqliteDataFrame::fill_col_value(const SEXP col, const int j) {
  switch (TYPEOF(col)) {
  case INTSXP:
    set_int_value(col, j);
    break;
  case REALSXP:
    set_real_value(col, j);
    break;
  case STRSXP:
    set_string_value(col, j);
    break;
  case VECSXP:
    set_raw_value(col, j);
    break;
  }
}

void SqliteDataFrame::set_int_value(const SEXP col, const int j) const {
  INTEGER(col)[i] = sqlite3_column_int(stmt, j);
}

void SqliteDataFrame::set_real_value(const SEXP col, const int j) const {
  REAL(col)[i] = sqlite3_column_double(stmt, j);
}

void SqliteDataFrame::set_string_value(const SEXP col, const int j) const {
  const char* const text = reinterpret_cast<const char*>(sqlite3_column_text(stmt, j));
  SET_STRING_ELT(col, i, Rf_mkCharCE(text, CE_UTF8));
}

void SqliteDataFrame::set_raw_value(const SEXP col, const int j) const {
  int size = sqlite3_column_bytes(stmt, j);
  const void* blob = sqlite3_column_blob(stmt, j);

  SEXP bytes = Rf_allocVector(RAWSXP, size);
  memcpy(RAW(bytes), blob, size);

  SET_VECTOR_ELT(col, i, bytes);
}

SEXPTYPE SqliteDataFrame::datatype_to_sexptype(const int field_type) {
  switch (field_type) {
  case SQLITE_INTEGER:
    return INTSXP;

  case SQLITE_FLOAT:
    return REALSXP;

  case SQLITE_TEXT:
    return STRSXP;

  case SQLITE_BLOB:
    // List of raw vectors
    return VECSXP;

  case SQLITE_NULL:
  default:
    return NILSXP;
  }
}

SEXPTYPE SqliteDataFrame::decltype_to_sexptype(const char* decl_type) {
  if (decl_type == NULL)
    return LGLSXP;

  char affinity = sqlite3AffinityType(decl_type);

  switch (affinity) {
  case SQLITE_AFF_INTEGER:
    return INTSXP;

  case SQLITE_AFF_NUMERIC:
  case SQLITE_AFF_REAL:
    return REALSXP;

  case SQLITE_AFF_TEXT:
    return STRSXP;

  case SQLITE_AFF_BLOB:
    return VECSXP;
  }

  // Shouldn't occur
  return LGLSXP;
}

