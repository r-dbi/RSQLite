#ifndef RSQLITE_SQLITEDATAFRAME_H
#define RSQLITE_SQLITEDATAFRAME_H


#include "sqlite3.h"
#include <boost/container/stable_vector.hpp>

class SqliteColumn;

class SqliteDataFrame {
  sqlite3_stmt* stmt;
  const int n_max;
  int i, n;
  boost::container::stable_vector<SqliteColumn> data;
  std::vector<std::string> names;

public:
  SqliteDataFrame(sqlite3_stmt* stmt, std::vector<std::string> names, const int n_max, const std::vector<SEXPTYPE>& types);
  ~SqliteDataFrame();

private:
  int init_n() const;

public:
  bool set_col_values();
  void advance();

  List get_data(std::vector<SEXPTYPE>& types);

private:
  void resize();
  void finalize_cols();
};


#endif //RSQLITE_SQLITEDATAFRAME_H
