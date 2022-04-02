#include "pch.h"
#include "SqliteColumnDataSource.h"
#include "integer64.h"
#include "affinity.h"
#include <boost/limits.hpp>
#include <boost/date_time/gregorian/gregorian.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/algorithm/string/predicate.hpp>


SqliteColumnDataSource::SqliteColumnDataSource(sqlite3_stmt* stmt_, const int j_, bool with_alt_types_) :
  DbColumnDataSource(j_),
  stmt(stmt_),
  with_alt_types(with_alt_types_)
{
}

DATA_TYPE SqliteColumnDataSource::get_data_type() const {

  if (with_alt_types) {
      DATA_TYPE decl_dt = get_decl_data_type();
      if (decl_dt == DT_DATE || decl_dt == DT_DATETIME || decl_dt == DT_TIME) {
          return decl_dt;
      }
  }

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
  return datatype_from_decltype(sqlite3_column_decltype(get_stmt(), get_j()), with_alt_types);
}

bool SqliteColumnDataSource::is_null() const {
  return get_column_type() == SQLITE_NULL;
}

int SqliteColumnDataSource::fetch_bool() const {
  // No such data type
  return 0;
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

double SqliteColumnDataSource::fetch_date() const {

  namespace bg = boost::gregorian;

  int dt = get_column_type();

  if (dt == SQLITE_TEXT) {
      const char* dtstr = reinterpret_cast<const char*>(sqlite3_column_text(get_stmt(), get_j()));
      double dateval;

      try {
          bg::date dt(bg::from_simple_string(dtstr));
          bg::date_duration delta = dt - bg::date(1970, 1, 1);
          dateval = static_cast<double>(delta.days());
      } catch (...) {
          Rcpp::warning("Unknown string format, NA is returned.");
          dateval = NA_REAL;
      }
      return dateval;
  } else if (dt == SQLITE_BLOB) {
    Rcpp::warning("Cannot convert blob, NA is returned.");
    return NA_REAL;
  } else {
      return static_cast<double>(sqlite3_column_int(get_stmt(), get_j()));
  }
}

double SqliteColumnDataSource::fetch_datetime_local() const {

  namespace bp = boost::posix_time;
  namespace bg = boost::gregorian;
  namespace bd = boost::date_time;

  int dt = get_column_type();

  if (dt == SQLITE_TEXT) {
      const char* dtstr = reinterpret_cast<const char*>(sqlite3_column_text(get_stmt(), get_j()));
      double dateval;
      try {
          bp::ptime dttm(bd::parse_delimited_time<bp::ptime>(dtstr, ' '));
          bp::time_duration delta = dttm - bp::ptime(bg::date(1970, 1, 1), bp::seconds(0));
          dateval = delta.total_microseconds() * 1e-6;
      } catch (...) {
          Rcpp::warning("Unknown string format, NA is returned.");
          dateval = NA_REAL;
      }
      return dateval;
  } else if (dt == SQLITE_BLOB) {
    Rcpp::warning("Cannot convert blob, NA is returned.");
    return NA_REAL;
  } else {
    return sqlite3_column_double(get_stmt(), get_j());
  }

}

double SqliteColumnDataSource::fetch_datetime() const {
  // No such data type
  return 0.0;
}

double SqliteColumnDataSource::fetch_time() const {


  namespace bp = boost::posix_time;

  int dt = get_column_type();

  if (dt == SQLITE_TEXT) {
    const char *tmstr = reinterpret_cast<const char*>(sqlite3_column_text(get_stmt(), get_j()));
    double dateval;
    try {
        bp::time_duration secs(bp::duration_from_string(tmstr));
        dateval = secs.total_microseconds() * 1e-6;
    } catch (...) {
        Rcpp::warning("Unknown string format, NA is returned.");
        dateval = NA_REAL;
    }
    return dateval;
  } else if (dt == SQLITE_BLOB) {
    Rcpp::warning("Cannot convert blob, NA is returned.");
    return NA_REAL;
  } else {
    return sqlite3_column_double(get_stmt(), get_j());
  }
}


DATA_TYPE SqliteColumnDataSource::datatype_from_decltype(const char* decl_type, bool with_alt_types) {
  if (decl_type == NULL)
    return DT_BOOL;

  if (with_alt_types) {
      if (boost::iequals(decl_type, "datetime") || boost::iequals(decl_type, "timestamp")) {
          return DT_DATETIME;
      } else if (boost::iequals(decl_type, "date")) {
          return DT_DATE;
      } else if (boost::iequals(decl_type, "time")) {
          return DT_TIME;
      }
  }

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
