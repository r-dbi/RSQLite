#ifndef RSQLITE_SQLITECOLUMN_H
#define RSQLITE_SQLITECOLUMN_H


#include "sqlite3.h"

class SqliteColumn {
  const int j, n_max;
  RObject data;
  SEXPTYPE type;
  int i, n;

public:
  SqliteColumn(SEXPTYPE type_, int j_, int n_max_);

private:
  int init_n() const;

public:
  void set_col_value(sqlite3_stmt* stmt);
  void finalize(sqlite3_stmt* stmt, const int n_);

  operator SEXP() const {
    return data;
  };

  SEXPTYPE get_type() const {
    return type;
  }

private:
  const RObject& get_value() const {
    return data;
  }

  void set_value(const RObject& data_) {
    data = data_;
  }

  void set_type(SEXPTYPE type_) {
    type = type_;
  }

  void resize() {
    set_value(Rf_lengthgets(get_value(), n));
    if (i > n) i = n;
  }

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
