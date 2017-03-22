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
};


#endif //RSQLITE_SQLITEDATAFRAME_H
