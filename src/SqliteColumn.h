#ifndef RSQLITE_SQLITECOLUMN_H
#define RSQLITE_SQLITECOLUMN_H


#include "sqlite3.h"

class SqliteColumn {
public:
  SqliteColumn(SEXPTYPE type_) : type(type_) {}

public:
  static SqliteColumn as(SEXPTYPE type_) { return SqliteColumn(type_); }
  static SEXPTYPE get_type_from_object(const SqliteColumn& col) { return col.get_type(); }

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
  }

private:
  RObject data;
  SEXPTYPE type;
};


#endif // RSQLITE_SQLITECOLUMN_H
