#ifndef RSQLITE_SQLITECOLUMN_H
#define RSQLITE_SQLITECOLUMN_H


#include "sqlite3.h"
#include "ColumnDataType.h"
#include <boost/shared_ptr.hpp>
#include <boost/ptr_container/ptr_vector.hpp>

class SqliteColumnDataSource;
class ColumnStorage;

class SqliteColumn {
private:
  boost::shared_ptr<SqliteColumnDataSource> source;
  const int n_max;
  boost::ptr_vector<ColumnStorage> storage;
  int i, n;

public:
  SqliteColumn(DATA_TYPE dt_, int n_max_, sqlite3_stmt* stmt_, int j_);
  ~SqliteColumn();

private:
  int init_n() const;

public:
  void set_col_value();
  void finalize(const int n_);

  operator SEXP() const;
  DATA_TYPE get_type() const;

private:
  ColumnStorage* get_last_storage();
  const ColumnStorage* get_last_storage() const;
};


#endif // RSQLITE_SQLITECOLUMN_H
