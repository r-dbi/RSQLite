#ifndef RSQLITE_SQLITECOLUMN_H
#define RSQLITE_SQLITECOLUMN_H


#include "sqlite3.h"
#include <boost/shared_ptr.hpp>

#include "ColumnDataType.h"

class SqliteColumnDataSource;

class SqliteColumn {
private:
  boost::shared_ptr<SqliteColumnDataSource> source;
  const int n_max;
  RObject data;
  DATA_TYPE dt;
  int i, n;

public:
  SqliteColumn(SEXPTYPE dt_, int n_max_, sqlite3_stmt* stmt_, int j_);
  ~SqliteColumn();

private:
  int init_n() const;

public:
  void set_col_value();
  void finalize(const int n_);

  operator SEXP() const;;
  SEXPTYPE get_type() const;

private:
  const RObject& get_value() const;
  void set_value(const RObject& data_);
  void set_type(SEXPTYPE type_);
  void resize();

  SEXP alloc_col(const SEXPTYPE type);
  void alloc_missing();

  void fill_default_col_value();

  void fill_col_value();
  void set_int_value() const;
  void set_real_value() const;
  void set_string_value() const;
  void set_raw_value() const;

  static unsigned int datatype_to_sexptype(const int field_type);
  static unsigned int decltype_to_sexptype(const char* decl_type);
};


#endif // RSQLITE_SQLITECOLUMN_H
