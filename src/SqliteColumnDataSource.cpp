#include "pch.h"
#include "SqliteColumnDataSource.h"
#include "integer64.h"
#include "affinity.h"
#include <boost/limits.hpp>

SqliteColumnDataSource::SqliteColumnDataSource(sqlite3_stmt* stmt_, const int j_) :
  DbColumnDataSource(j_),
  stmt(stmt_)
{
}

DATA_TYPE SqliteColumnDataSource::get_data_type() const {
  const int field_type = get_column_type();
  switch (field_type) {
  case SQLITE_INTEGER:
    {
      int64_t ret = sqlite3_column_int64(get_stmt(), get_j());
      if (needs_64_bit(ret))
        return DT_INT64;
      else
        return DT_INT;
    }

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

bool SqliteColumnDataSource::is_null() const {
  return get_column_type() == SQLITE_NULL;
}

int SqliteColumnDataSource::fetch_int() const {
  return sqlite3_column_int(get_stmt(), get_j());
}

int64_t SqliteColumnDataSource::fetch_int64() const {
  return sqlite3_column_int64(get_stmt(), get_j());
}

double SqliteColumnDataSource::fetch_real() const {
  return sqlite3_column_double(get_stmt(), get_j());
}

SEXP SqliteColumnDataSource::fetch_string() const {
  LOG_VERBOSE;
  const char* const text = reinterpret_cast<const char*>(sqlite3_column_text(get_stmt(), get_j()));
  return Rf_mkCharCE(text, CE_UTF8);
}

SEXP SqliteColumnDataSource::fetch_blob() const {
  int size = sqlite3_column_bytes(get_stmt(), get_j());
  const void* blob = sqlite3_column_blob(get_stmt(), get_j());

  SEXP bytes = Rf_allocVector(RAWSXP, size);
  memcpy(RAW(bytes), blob, size);

  return bytes;
}


DATA_TYPE SqliteColumnDataSource::datatype_from_decltype(const char* decl_type) {
  if (decl_type == NULL)
    return DT_BOOL;

  char affinity = sqlite3AffinityType(decl_type);

  switch (affinity) {
  case SQLITE_AFF_INTEGER:
    return DT_INT;

  case SQLITE_AFF_NUMERIC:
  case SQLITE_AFF_REAL:
    return DT_REAL;

  case SQLITE_AFF_TEXT:
    return DT_STRING;

  case SQLITE_AFF_BLOB:
    return DT_BLOB;
  }

  // Shouldn't occur
  return DT_BOOL;
}

sqlite3_stmt* SqliteColumnDataSource::get_stmt() const {
  return stmt;
}

int SqliteColumnDataSource::get_column_type() const {
  return sqlite3_column_type(get_stmt(), get_j());
}

bool SqliteColumnDataSource::needs_64_bit(const int64_t ret) {
  return ret < std::numeric_limits<int32_t>::min() || ret > std::numeric_limits<int32_t>::max();
}
