#ifndef RSQLITE_SQLITEDATAFRAME_H
#define RSQLITE_SQLITEDATAFRAME_H


#include "sqlite3.h"
#include <boost/container/stable_vector.hpp>
#include <boost/scoped_ptr.hpp>
#include "DbColumnDataType.h"

class DbColumn;
class DbColumnDataSourceFactory;

class SqliteDataFrame {
  boost::scoped_ptr<DbColumnDataSourceFactory> factory;
  const int n_max;
  int i;
  boost::container::stable_vector<DbColumn> data;
  std::vector<std::string> names;

public:
  SqliteDataFrame(sqlite3_stmt* stmt, std::vector<std::string> names, const int n_max_, const std::vector<DATA_TYPE>& types);
  ~SqliteDataFrame();

public:
  void set_col_values();
  bool advance();

  List get_data(std::vector<DATA_TYPE>& types);
  size_t get_ncols() const;

private:
  void finalize_cols();
};


#endif //RSQLITE_SQLITEDATAFRAME_H
