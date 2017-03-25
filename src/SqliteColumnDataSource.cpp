#include <plogr.h>
#include "SqliteColumnDataSource.h"

SqliteColumnDataSource::SqliteColumnDataSource(sqlite3_stmt* stmt_, const int j_)
  :
  stmt(stmt_),
  j(j_)
{
}

sqlite3_stmt* SqliteColumnDataSource::get_stmt() const {
  return stmt;
}

int SqliteColumnDataSource::get_j() const {
  return j;
}

DATA_TYPE SqliteColumnDataSource::get_data_type() const {
  const int field_type = get_column_type();
  switch (field_type) {
  case SQLITE_INTEGER:
    return DT_INT;

  case SQLITE_FLOAT:
    return DT_REAL;

  case SQLITE_TEXT:
    return DT_STRING;

  case SQLITE_BLOB:
    // List of raw vectors
    return DT_BLOB;

  case SQLITE_NULL:
  default:
    return DT_UNKNOWN;
  }
}

DATA_TYPE SqliteColumnDataSource::get_decl_data_type() const {
  return datatype_from_decltype(sqlite3_column_decltype(get_stmt(), get_j()));
}

int SqliteColumnDataSource::get_column_type() const {
  return sqlite3_column_type(get_stmt(), get_j());
}

bool SqliteColumnDataSource::is_null() const {
  return get_column_type() == SQLITE_NULL;
}

void SqliteColumnDataSource::fetch_int(Rcpp::IntegerVector x, int i) const {
  x[i] = sqlite3_column_int(get_stmt(), get_j());
}

void SqliteColumnDataSource::fetch_real(Rcpp::NumericVector x, int i) const {
  x[i] = sqlite3_column_double(get_stmt(), get_j());
}

void SqliteColumnDataSource::fetch_string(Rcpp::CharacterVector x, int i) const {
  LOG_VERBOSE;
  const char* const text = reinterpret_cast<const char*>(sqlite3_column_text(get_stmt(), get_j()));
  x[i] = Rf_mkCharCE(text, CE_UTF8);
}

void SqliteColumnDataSource::fetch_blob(Rcpp::List x, int i) const {
  int size = sqlite3_column_bytes(get_stmt(), get_j());
  const void* blob = sqlite3_column_blob(get_stmt(), get_j());

  SEXP bytes = Rf_allocVector(RAWSXP, size);
  memcpy(RAW(bytes), blob, size);

  x[i] = bytes;
}
