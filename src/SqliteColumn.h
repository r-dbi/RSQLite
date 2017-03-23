#ifndef RSQLITE_SQLITECOLUMN_H
#define RSQLITE_SQLITECOLUMN_H


#include "sqlite3.h"

class SqliteColumn {
public:
  SqliteColumn(SEXPTYPE type_, int j_) : type(type_), i(0), j(j_) {}

public:
  const RObject& get_value() const {
    return data;
  }

  void set_value(const RObject& data_) {
    data = data_;
  }

  SEXPTYPE get_type() const {
    return type;
  }

  void set_type(SEXPTYPE type_) {
    type = type_;
  }

  operator SEXP() const {
    return data;
  };

  void resize(const int n) {
    set_value(Rf_lengthgets(get_value(), n));
    if (i > n) i = n;
  }

  void set_col_value(sqlite3_stmt* stmt, const int n);
  void finalize(sqlite3_stmt* stmt, const int n);

  SEXP alloc_col(const SEXPTYPE type, const int n);
  void alloc_missing(sqlite3_stmt* stmt, const int n);

  void fill_default_col_value();

  void fill_col_value(sqlite3_stmt* stmt);
  void set_int_value(sqlite3_stmt* stmt) const;
  void set_real_value(sqlite3_stmt* stmt) const;
  void set_string_value(sqlite3_stmt* stmt) const;
  void set_raw_value(sqlite3_stmt* stmt) const ;

  static unsigned int datatype_to_sexptype(const int field_type);
  static unsigned int decltype_to_sexptype(const char* decl_type);

private:
  RObject data;
  SEXPTYPE type;
  int i;
  const int j;
};


#endif // RSQLITE_SQLITECOLUMN_H
