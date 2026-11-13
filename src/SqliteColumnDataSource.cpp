#include "pch.h"
#include "SqliteColumnDataSource.h"
#include "integer64.h"
#include "affinity.h"
#include <boost/limits.hpp>
#include <boost/date_time/gregorian/gregorian.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/algorithm/string/predicate.hpp>
#include <cmath>
#include <stdexcept>
#include <string>

namespace {

bool is_ascii_digit(char c) {
  return c >= '0' && c <= '9';
}

bool is_ascii_space(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
         c == '\v';
}

// Splits a trailing UTC offset off a time or timestamp,
// in the forms SQLite's date and time functions accept:
// `Z`, or a sign, two digits for hours up to 14, a colon and two digits for
// minutes, optionally surrounded by whitespace. Returns the text before the
// offset, and stores whether there is one and its value in seconds east of UTC.
// Anything else after the time that starts with a sign or `Z` throws,
// because boost would read it as part of the time.
std::string split_utc_offset(
  const char* str,
  bool& has_offset,
  int& offset_secs
) {
  std::string text(str);
  has_offset = false;
  offset_secs = 0;

  // The offset can only follow the time,
  // so it is looked for after the first colon.
  const std::string::size_type colon = text.find(':');
  if (colon == std::string::npos) {
    return text;
  }
  const std::string::size_type pos = text.find_first_of("+-Zz", colon);
  if (pos == std::string::npos) {
    return text;
  }

  std::string::size_type end = pos + 1;
  const char sign = text[pos];
  if (sign == '+' || sign == '-') {
    if (text.size() < pos + 6 || !is_ascii_digit(text[pos + 1]) ||
        !is_ascii_digit(text[pos + 2]) || text[pos + 3] != ':' ||
        !is_ascii_digit(text[pos + 4]) || !is_ascii_digit(text[pos + 5])) {
      throw std::invalid_argument("Invalid UTC offset");
    }
    const int hours = (text[pos + 1] - '0') * 10 + (text[pos + 2] - '0');
    const int minutes = (text[pos + 4] - '0') * 10 + (text[pos + 5] - '0');
    if (hours > 14 || minutes > 59) {
      throw std::invalid_argument("Invalid UTC offset");
    }
    offset_secs = (sign == '-' ? -1 : 1) * (hours * 3600 + minutes * 60);
    end = pos + 6;
  }

  for (; end < text.size(); ++end) {
    if (!is_ascii_space(text[end])) {
      throw std::invalid_argument("Invalid UTC offset");
    }
  }

  has_offset = true;
  std::string::size_type value_end = pos;
  while (value_end > 0 && is_ascii_space(text[value_end - 1])) {
    --value_end;
  }
  return text.substr(0, value_end);
}

// Throws unless a time with an offset is a time of day
// in the form SQLite's `time()` accepts: `HH:MM`, `HH:MM:SS` or `HH:MM:SS.SSS`,
// with hours up to 24 and minutes and seconds up to 59.
// Boost reads any duration, such as `25:00:00` or `12:60:00`.
void check_time_of_day(const std::string& text) {
  const std::string::size_type n = text.size();
  bool valid = n >= 5 && is_ascii_digit(text[0]) && is_ascii_digit(text[1]) &&
               text[2] == ':' && is_ascii_digit(text[3]) &&
               is_ascii_digit(text[4]) &&
               (text[0] - '0') * 10 + (text[1] - '0') <= 24 && text[3] <= '5';
  if (valid && n > 5) {
    valid = n >= 8 && text[5] == ':' && is_ascii_digit(text[6]) &&
            is_ascii_digit(text[7]) && text[6] <= '5';
    if (valid && n > 8) {
      valid = n >= 10 && text[8] == '.';
      for (std::string::size_type i = 9; valid && i < n; ++i) {
        valid = is_ascii_digit(text[i]);
      }
    }
  }
  if (!valid) {
    throw std::invalid_argument("Invalid time of day");
  }
}

}  // namespace

SqliteColumnDataSource::SqliteColumnDataSource(
  sqlite3_stmt* stmt_,
  const int j_,
  bool with_alt_types_
)
    : DbColumnDataSource(j_), stmt(stmt_), with_alt_types(with_alt_types_) {}

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
      if (needs_64_bit(ret)) {
        return DT_INT64;
      } else {
        return DT_INT;
      }
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
  return datatype_from_decltype(
    sqlite3_column_decltype(get_stmt(), get_j()),
    with_alt_types
  );
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
  const char* const text =
    reinterpret_cast<const char*>(sqlite3_column_text(get_stmt(), get_j()));
  return Rf_mkCharCE(text, CE_UTF8);
}

SEXP SqliteColumnDataSource::fetch_blob() const {
  // Keep sqlite3_column_bytes() before sqlite3_column_blob():
  // the out-of-memory check below relies on the size
  // being read before sqlite3_column_blob() tries to expand the value.
  int size = sqlite3_column_bytes(get_stmt(), get_j());
  const void* blob = sqlite3_column_blob(get_stmt(), get_j());

  // An empty blob may come back as a NULL pointer,
  // which must not reach memcpy().
  if (size == 0) {
    return Rf_allocVector(RAWSXP, 0);
  }
  // A NULL pointer with a nonzero size means that SQLite ran out of memory.
  if (blob == NULL) {
    cpp11::stop("Out of memory while fetching a blob of %d bytes.", size);
  }

  SEXP bytes = Rf_allocVector(RAWSXP, size);
  memcpy(RAW(bytes), blob, size);

  return bytes;
}

double SqliteColumnDataSource::fetch_date() const {
  namespace bg = boost::gregorian;

  int dt = get_column_type();

  if (dt == SQLITE_TEXT) {
    const char* dtstr =
      reinterpret_cast<const char*>(sqlite3_column_text(get_stmt(), get_j()));
    double dateval;

    try {
      bg::date dt(bg::from_simple_string(dtstr));
      bg::date_duration delta = dt - bg::date(1970, 1, 1);
      dateval = static_cast<double>(delta.days());
    } catch (...) {
      cpp11::warning(std::string("Unknown string format, NA is returned."));
      dateval = NA_REAL;
    }
    return dateval;
  } else if (dt == SQLITE_BLOB) {
    cpp11::warning(std::string("Cannot convert blob, NA is returned."));
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
    const char* dtstr =
      reinterpret_cast<const char*>(sqlite3_column_text(get_stmt(), get_j()));
    double dateval;
    try {
      bool has_offset;
      int offset_secs;
      const std::string text = split_utc_offset(dtstr, has_offset, offset_secs);
      bp::ptime dttm(bd::parse_delimited_time<bp::ptime>(text, ' '));
      bp::time_duration delta =
        dttm - bp::ptime(bg::date(1970, 1, 1), bp::seconds(0));
      // A time east of UTC is ahead of it, as in SQLite's `datetime()`.
      dateval = delta.total_microseconds() * 1e-6 - offset_secs;
    } catch (...) {
      cpp11::warning(std::string("Unknown string format, NA is returned."));
      dateval = NA_REAL;
    }
    return dateval;
  } else if (dt == SQLITE_BLOB) {
    cpp11::warning(std::string("Cannot convert blob, NA is returned."));
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
    const char* tmstr =
      reinterpret_cast<const char*>(sqlite3_column_text(get_stmt(), get_j()));
    double dateval;
    try {
      bool has_offset;
      int offset_secs;
      const std::string text = split_utc_offset(tmstr, has_offset, offset_secs);
      if (has_offset) {
        check_time_of_day(text);
      }
      bp::time_duration secs(bp::duration_from_string(text));
      dateval = secs.total_microseconds() * 1e-6;
      if (has_offset) {
        // As in SQLite's `time()`,
        // a time with an offset is a time of day in UTC,
        // and hour 24 is allowed only for 24:00:00.
        if (dateval > 86400.0) {
          throw std::invalid_argument("Invalid time of day");
        }
        dateval = std::fmod(dateval - offset_secs, 86400.0);
        if (dateval < 0) {
          dateval += 86400.0;
        }
      }
    } catch (...) {
      cpp11::warning(std::string("Unknown string format, NA is returned."));
      dateval = NA_REAL;
    }
    return dateval;
  } else if (dt == SQLITE_BLOB) {
    cpp11::warning(std::string("Cannot convert blob, NA is returned."));
    return NA_REAL;
  } else {
    return sqlite3_column_double(get_stmt(), get_j());
  }
}

DATA_TYPE SqliteColumnDataSource::datatype_from_decltype(
  const char* decl_type,
  bool with_alt_types
) {
  if (decl_type == NULL) {
    return DT_BOOL;
  }

  if (with_alt_types) {
    if (boost::iequals(decl_type, "datetime") ||
        boost::iequals(decl_type, "timestamp")) {
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
  return ret < std::numeric_limits<int32_t>::min() ||
         ret > std::numeric_limits<int32_t>::max();
}
