#ifndef RSQLITE_SQLITECOLUMN_H
#define RSQLITE_SQLITECOLUMN_H


#include "sqlite3.h"

class SqliteColumn {
public:
  const RObject& get_value() const {
    return data;
  }

  void set_value(const RObject& data_) {
    data = data_;
  }

  operator SEXP() const {
    return data;
  };

  void resize(const int n) {
    set_value(Rf_lengthgets(get_value(), n));
  }

private:
  RObject data;
};


#endif // RSQLITE_SQLITECOLUMN_H
