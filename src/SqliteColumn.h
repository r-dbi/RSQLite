#ifndef RSQLITE_SQLITECOLUMN_H
#define RSQLITE_SQLITECOLUMN_H


#include "sqlite3.h"

class SqliteColumn {
public:
  enum DATA_TYPE {
    DT_UNKNOWN = NILSXP,
    DT_INT = INTSXP,
    DT_REAL = REALSXP,
    DT_STRING = STRSXP,
    DT_BLOB = VECSXP,
  };

private:
  const int j, n_max;
  RObject data;
  enum DATA_TYPE dt;
  int i, n;

public:
  SqliteColumn(SEXPTYPE dt_, int j_, int n_max_);

private:
  int init_n() const;

public:
  void set_col_value(sqlite3_stmt* stmt);
  void finalize(sqlite3_stmt* stmt, const int n_);

  operator SEXP() const;;
  SEXPTYPE get_type() const;

private:
  const RObject& get_value() const;
  void set_value(const RObject& data_);
  void set_type(SEXPTYPE type_);
  void resize();

  SEXP alloc_col(const SEXPTYPE type);
  void alloc_missing(sqlite3_stmt* stmt);

  void fill_default_col_value();

  void fill_col_value(sqlite3_stmt* stmt);
  void set_int_value(sqlite3_stmt* stmt) const;
  void set_real_value(sqlite3_stmt* stmt) const;
  void set_string_value(sqlite3_stmt* stmt) const;
  void set_raw_value(sqlite3_stmt* stmt) const;

  static unsigned int datatype_to_sexptype(const int field_type);
  static unsigned int decltype_to_sexptype(const char* decl_type);
};


#endif // RSQLITE_SQLITECOLUMN_H
