#ifndef RSQLITE_COLUMNSTORAGE_H
#define RSQLITE_COLUMNSTORAGE_H


#include "ColumnDataType.h"


class SqliteColumnDataSource;

class ColumnStorage {
  Rcpp::RObject data;
  int i;
  DATA_TYPE dt;
  const int n_max;
  const SqliteColumnDataSource& source;

public:
  ColumnStorage(DATA_TYPE dt_, const R_xlen_t capacity_, const int n_max_, const SqliteColumnDataSource& source_);
  ~ColumnStorage();

public:
  ColumnStorage* append_col();

  DATA_TYPE get_item_data_type() const;
  DATA_TYPE get_data_type() const;
  static SEXP allocate(const R_xlen_t length, DATA_TYPE dt);
  int copy_to(SEXP x, DATA_TYPE dt, const int pos) const;

private:
  // append_col()
  R_xlen_t get_capacity() const;
  R_xlen_t get_new_capacity(const R_xlen_t desired_capacity) const;

  ColumnStorage* append_null();
  void fill_default_value();

  ColumnStorage* append_data();
  ColumnStorage* append_data_to_new(DATA_TYPE new_dt);
  void fetch_value();

  // allocate()
  static SEXPTYPE sexptype_from_datatype(DATA_TYPE type);
  static Rcpp::RObject class_from_datatype(DATA_TYPE dt);

  // copy_to()
  static void fill_default_value(SEXP data, DATA_TYPE dt, R_xlen_t i);
  void copy_value(SEXP x, DATA_TYPE dt, const int tgt, const int src) const;
};


#endif // RSQLITE_COLUMNSTORAGE_H
