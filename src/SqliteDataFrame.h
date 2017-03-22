#ifndef RSQLITE_SQLITEDATAFRAME_H
#define RSQLITE_SQLITEDATAFRAME_H


#include "sqlite3.h"
#include "SqliteColumn.h"

class SqliteDataFrame {
  sqlite3_stmt* stmt;
  const int n_max;
  int i, n;
  std::vector<SqliteColumn> data;
  std::vector<std::string> names;
  std::vector<SEXPTYPE> types;

public:
  SqliteDataFrame(sqlite3_stmt* stmt, std::vector<std::string> names, const int n_max, const std::vector<SEXPTYPE>& types);

private:
  int init_n() const;

public:
  bool set_col_values();
  void advance();

  List get_data(std::vector<SEXPTYPE>& types);

private:
  void resize();
  void finalize_cols();
  void alloc_missing_cols();

  void set_col_value(RObject& col, const int j);
  SEXP alloc_col(const unsigned int type);
  void fill_default_col_value(SEXP col);

  static void fill_default_col_value(SEXP col, const int i_);
  void fill_col_value(const SEXP col, const int j);

  void set_int_value(const SEXP col, const int j) const;
  void set_real_value(const SEXP col, const int j) const;
  void set_string_value(const SEXP col, const int j) const;
  void set_raw_value(SEXP col, const int j) const ;

  static unsigned int datatype_to_sexptype(const int field_type);
  static unsigned int decltype_to_sexptype(const char* decl_type);
};


#endif //RSQLITE_SQLITEDATAFRAME_H
