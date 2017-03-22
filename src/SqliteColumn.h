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

private:
  RObject data;
};


#endif // RSQLITE_SQLITECOLUMN_H
