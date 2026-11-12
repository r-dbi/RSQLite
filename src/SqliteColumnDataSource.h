#ifndef RSQLITE_SQLITECOLUMNDATASOURCE_H
#define RSQLITE_SQLITECOLUMNDATASOURCE_H

#include "sqlite3-cpp.h"
#include "DbColumnDataSource.h"

class SqliteColumnDataSource : public DbColumnDataSource {
  sqlite3_stmt* stmt;
  const bool with_alt_types;

public:
  SqliteColumnDataSource(sqlite3_stmt* stmt, const int j, bool with_alt_types);

public:
  virtual DATA_TYPE get_data_type() const;
  virtual DATA_TYPE get_decl_data_type() const;

  virtual bool is_null() const;

  virtual int fetch_bool() const;
  virtual int fetch_int() const;
  virtual int64_t fetch_int64() const;
  virtual double fetch_real() const;
  virtual SEXP fetch_string() const;
  virtual SEXP fetch_blob() const;
  virtual double fetch_date() const;
  virtual double fetch_datetime_local() const;
  virtual double fetch_datetime() const;
  virtual double fetch_time() const;

  // The parsers of the text that fetch_date(), fetch_time() and
  // fetch_datetime_local() read, without their warning:
  // false if `text` can't be parsed.
  // A date is parsed into days since 1970-01-01, a time into microseconds,
  // and a timestamp into microseconds since 1970-01-01 00:00:00.
  static bool parse_date(const char* text, int64_t& days);
  static bool parse_time(const char* text, int64_t& micros);
  static bool parse_datetime_local(const char* text, int64_t& micros);

private:
  static DATA_TYPE datatype_from_decltype(
    const char* decl_type,
    bool with_alt_types
  );

private:
  sqlite3_stmt* get_stmt() const;
  const char* get_text() const;

  int get_column_type() const;

  static bool needs_64_bit(const int64_t ret);
};

#endif  // RSQLITE_SQLITECOLUMNDATASOURCE_H
