#include <RSQLite.h>
#include "SqliteColumn.h"
#include "affinity.h"


SqliteColumn::SqliteColumn(SEXPTYPE dt_, int j_, int n_max_)
  : dt((DATA_TYPE)dt_),
    j(j_),
    n_max(n_max_),
    i(0),
    n(init_n())
{

}

int SqliteColumn::init_n() const {
  if (n_max >= 0)
    return n_max;

  return 100;
}

void SqliteColumn::set_col_value(sqlite3_stmt* stmt) {
  if (i >= n) {
    // No dynamic reallocation if n_max is given
    if (n_max >= 0) return;

    n *= 2;
    resize();
  }

  // col needs to be PROTECTed because it can be allocated
  // just before a RAW vector that holds BLOB data is (#192).
  // The easiest way to protect is to make it an RObject.

  SEXPTYPE type = get_type();
  int column_type = sqlite3_column_type(stmt, j);

  LOG_VERBOSE << "column_type: " << column_type;
  LOG_VERBOSE << "type: " << type;

  if (type == NILSXP) {
    LOG_VERBOSE << "datatype_to_sexptype\n";
    type = datatype_to_sexptype(column_type);
    LOG_VERBOSE << "type: " << type;
  }

  if (Rf_isNull(data)) {
    if (type == NILSXP) {
      ++i;
      return;
    }
    else {
      set_type(type);
      alloc_col(type);
    }
  }

  if (column_type == SQLITE_NULL) {
    fill_default_col_value();
  }
  else {
    fill_col_value(stmt);
  }
  ++i;
  return;
}

void SqliteColumn::finalize(sqlite3_stmt* stmt, const int n_) {
  n = n_;
  resize();

  // Create data for columns where all values were NULL (or for all columns
  // in the case of a 0-row data frame)
  alloc_missing(stmt);
}

SqliteColumn::operator SEXP() const {
  return data;
}

SEXPTYPE SqliteColumn::get_type() const {
  return (SEXPTYPE)dt;
}

const RObject& SqliteColumn::get_value() const {
  return data;
}

void SqliteColumn::set_value(const RObject& data_) {
  data = data_;
}

void SqliteColumn::set_type(SEXPTYPE dt_) {
  dt = (DATA_TYPE)dt_;
}

void SqliteColumn::resize() {
  set_value(Rf_lengthgets(get_value(), n));
  if (i > n) i = n;
}

SEXP SqliteColumn::alloc_col(const SEXPTYPE type) {
  data = Rf_allocVector(type, n);
  int i_ = i;
  for (i = 0; i < i_; ++i) {
    fill_default_col_value();
  }
  return data;
}

void SqliteColumn::fill_default_col_value() {
  switch (TYPEOF(data)) {
  case LGLSXP:
    LOGICAL(data)[i] = NA_LOGICAL;
    break;
  case INTSXP:
    INTEGER(data)[i] = NA_INTEGER;
    break;
  case REALSXP:
    REAL(data)[i] = NA_REAL;
    break;
  case STRSXP:
    SET_STRING_ELT(data, i, NA_STRING);
    break;
  case VECSXP:
    SET_VECTOR_ELT(data, i, R_NilValue);
    break;
  }
}

void SqliteColumn::alloc_missing(sqlite3_stmt* stmt) {
  if (get_type() != NILSXP) return;

  SEXPTYPE type =
    decltype_to_sexptype(sqlite3_column_decltype(stmt, j));
  LOG_VERBOSE << j << ": " << type;
  set_type(type);
  alloc_col(type);
}

void SqliteColumn::fill_col_value(sqlite3_stmt* stmt) {
  switch (TYPEOF(data)) {
  case INTSXP:
    set_int_value(stmt);
    break;
  case REALSXP:
    set_real_value(stmt);
    break;
  case STRSXP:
    set_string_value(stmt);
    break;
  case VECSXP:
    set_raw_value(stmt);
    break;
  }
}

void SqliteColumn::set_int_value(sqlite3_stmt* stmt) const {
  INTEGER(data)[i] = sqlite3_column_int(stmt, j);
}

void SqliteColumn::set_real_value(sqlite3_stmt* stmt) const {
  REAL(data)[i] = sqlite3_column_double(stmt, j);
}

void SqliteColumn::set_string_value(sqlite3_stmt* stmt) const {
  LOG_VERBOSE;
  const char* const text = reinterpret_cast<const char*>(sqlite3_column_text(stmt, j));
  SET_STRING_ELT(data, i, Rf_mkCharCE(text, CE_UTF8));
}

void SqliteColumn::set_raw_value(sqlite3_stmt* stmt) const {
  int size = sqlite3_column_bytes(stmt, j);
  const void* blob = sqlite3_column_blob(stmt, j);

  SEXP bytes = Rf_allocVector(RAWSXP, size);
  memcpy(RAW(bytes), blob, size);

  SET_VECTOR_ELT(data, i, bytes);
}

SEXPTYPE SqliteColumn::datatype_to_sexptype(const int field_type) {
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

SEXPTYPE SqliteColumn::decltype_to_sexptype(const char* decl_type) {
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
