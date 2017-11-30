#ifndef RSQLITE_SQLITECOLUMNDATASOURCE_H
#define RSQLITE_SQLITECOLUMNDATASOURCE_H

#include "sqlite3.h"
#include "DbColumnDataSource.h"

class SqliteColumnDataSource : public DbColumnDataSource {
  sqlite3_stmt* stmt;

public:
  SqliteColumnDataSource(sqlite3_stmt* stmt, const int j);

public:
  DATA_TYPE get_data_type() const;
  DATA_TYPE get_decl_data_type() const;

  bool is_null() const;

  void fetch_int(SEXP x, int i) const;
  void fetch_int64(SEXP x, int i) const;
  void fetch_real(SEXP x, int i) const;
  void fetch_string(SEXP x, int i) const;
  void fetch_blob(SEXP x, int i) const;

private:
  static DATA_TYPE datatype_from_decltype(const char* decl_type);

private:
  sqlite3_stmt* get_stmt() const;

  int get_column_type() const;

  static bool needs_64_bit(const int64_t ret);
};

#endif // RSQLITE_SQLITECOLUMNDATASOURCE_H
