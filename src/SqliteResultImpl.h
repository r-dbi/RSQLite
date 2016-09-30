#ifndef RSQLITE_SQLITERESULTIMPL_H
#define RSQLITE_SQLITERESULTIMPL_H


#include <boost/noncopyable.hpp>
#include "sqlite3/sqlite3.h"

class SqliteResultImpl : public boost::noncopyable {
private:
  sqlite3* conn;
  sqlite3_stmt* pStatement_;
  bool complete_;
  bool ready_;
  int nrows_;
  int ncols_;
  int rows_affected_;
  int nparams_;
  std::vector<SEXPTYPE> types_;
  std::vector<std::string> names_;

public:
  SqliteResultImpl(sqlite3* conn_, const std::string& sql);
  ~SqliteResultImpl();

private:
  void prepare(const std::string& sql);
  void init_if_bound();
  void init();
  void cache_field_data();

public:
  bool complete() {
    return complete_;
  }

  int nrows() {
    return nrows_;
  }

  int rows_affected() {
    return rows_affected_;
  }

public:
  IntegerVector find_params_impl(const CharacterVector& param_names);
  void bind_impl(const List& params);
  void bind_rows_impl(const List& params);
  List fetch_impl(const int n_max);
  List get_column_info_impl();

private:
  void bind_parameter(int i, int j, const std::__cxx11::string& name, SEXP values_);
  int find_parameter(const std::__cxx11::string& name);
  void bind_parameter_pos(int i, int j, SEXP value_);

  List fetch_rows(int n_max, int& n);
  void step();
  List peek_first_row();
  List alloc_missing_cols(List data, int n);

  void set_col_values(List& out, const int i, const int n);
  void set_col_value(SEXP& col, const int i, const int j, const int n);
  SEXP alloc_col(const unsigned int type, const int i, const int n);
  void fill_default_col_value(SEXP col, const int i, const unsigned int type);
  void fill_col_value(const SEXP col, const int i, const int j,
                      unsigned int type);
  void set_raw_value(SEXP col, const int i, const int j);

  static unsigned int datatype_to_sexptype(const int field_type);
  static unsigned int decltype_to_sexptype(const char* decl_type);

  void raise_sqlite_exception() const;
};


#endif //RSQLITE_SQLITERESULTIMPL_H
