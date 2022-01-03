#ifndef RSQLITE_SQLITECOLUMNDATASOURCE_H
#define RSQLITE_SQLITECOLUMNDATASOURCE_H

#include "sqlite3.hpp"
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

private:
  static DATA_TYPE datatype_from_decltype(const char* decl_type, bool with_alt_types);

private:
  sqlite3_stmt* get_stmt() const;

  int get_column_type() const;

  static bool needs_64_bit(const int64_t ret);
};

#endif // RSQLITE_SQLITECOLUMNDATASOURCE_H
