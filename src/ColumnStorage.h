#ifndef RSQLITE_COLUMNSTORAGE_H
#define RSQLITE_COLUMNSTORAGE_H


#include <Rcpp.h>
#include "ColumnDataType.h"


class SqliteColumnDataSource;

class ColumnStorage {
  Rcpp::RObject data;
  int i;
  DATA_TYPE dt;
  const int capacity, n_max;
  const SqliteColumnDataSource& source;

public:
  ColumnStorage(DATA_TYPE dt_, const int capacity_, const int n_max_, const SqliteColumnDataSource& source_);
  ~ColumnStorage();

  ColumnStorage* append_col();

  DATA_TYPE get_data_type() const;
  int copy_to(SEXP x, DATA_TYPE dt, const int pos, const int n) const;

  static SEXP allocate(const int length, DATA_TYPE dt);

private:
  void fill_default_col_value();
  static void fill_default_value(SEXP data, DATA_TYPE dt, R_xlen_t i);

  void fill_col_value();

  ColumnStorage* append_null();

  ColumnStorage* append_data();
  ColumnStorage* append_data_to_new(DATA_TYPE new_dt);

  SEXP allocate(const int capacity) const;
};


#endif // RSQLITE_COLUMNSTORAGE_H
