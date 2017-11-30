#ifndef RSQLITE_SQLITECOLUMN_H
#define RSQLITE_SQLITECOLUMN_H


#include "sqlite3.h"
#include "DbColumnDataType.h"
#include <boost/shared_ptr.hpp>
#include <boost/ptr_container/ptr_vector.hpp>

class SqliteColumnDataSource;
class DbColumnStorage;

class SqliteColumn {
private:
  boost::shared_ptr<SqliteColumnDataSource> source;
  boost::ptr_vector<DbColumnStorage> storage;
  int i, n;
  std::set<DATA_TYPE> data_types_seen;

public:
  SqliteColumn(DATA_TYPE dt_, int n_max_, sqlite3_stmt* stmt_, int j_);
  ~SqliteColumn();

public:
  void set_col_value();
  void finalize(const int n_);
  void warn_type_conflicts(const String& name) const;

  operator SEXP() const;
  DATA_TYPE get_type() const;
  static const char* format_data_type(const DATA_TYPE dt);

private:
  DbColumnStorage* get_last_storage();
  const DbColumnStorage* get_last_storage() const;
};


#endif // RSQLITE_SQLITECOLUMN_H
