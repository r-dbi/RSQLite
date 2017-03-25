#ifndef RSQLITE_SQLITECOLUMNDATASOURCE_H
#define RSQLITE_SQLITECOLUMNDATASOURCE_H

#include "sqlite3.h"
#include "ColumnDataType.h"
#include <Rcpp.h>

class SqliteColumnDataSource {
  sqlite3_stmt* stmt;
  const int j;

public:
  SqliteColumnDataSource(sqlite3_stmt* stmt, const int j);

public:
  DATA_TYPE get_data_type() const;
  DATA_TYPE get_decl_data_type() const;

  bool is_null() const;

  void fetch_int(Rcpp::IntegerVector x, int i) const;
  void fetch_int64(Rcpp::NumericVector x, int i) const;
  void fetch_real(Rcpp::NumericVector x, int i) const;
  void fetch_string(Rcpp::CharacterVector x, int i) const;
  void fetch_blob(Rcpp::List x, int i) const;

private:
  static DATA_TYPE datatype_from_decltype(const char* decl_type);

private:
  sqlite3_stmt* get_stmt() const;
  int get_j() const;

  int get_column_type() const;

  static bool needs_64_bit(const int64_t ret);
};

#endif // RSQLITE_SQLITECOLUMNDATASOURCE_H
