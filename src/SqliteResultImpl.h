#ifndef RSQLITE_SQLITERESULTIMPL_H
#define RSQLITE_SQLITERESULTIMPL_H


#include <boost/noncopyable.hpp>
#include "sqlite3/sqlite3.h"

class SqliteResultImpl : public boost::noncopyable {
private:
  // Wrapped pointer
  sqlite3* conn;
  sqlite3_stmt* stmt;

  // Cache
  struct _cache {
    const std::vector<std::string> names_;
    const int ncols_;
    const int nparams_;

    _cache(sqlite3_stmt* stmt);

    static std::vector<std::string> get_column_names(sqlite3_stmt* stmt);
  } cache;

  // State
  bool complete_;
  bool ready_;
  int nrows_;
  int rows_affected_;
  std::vector<SEXPTYPE> types_;

public:
  SqliteResultImpl(sqlite3* conn_, const std::string& sql);
  ~SqliteResultImpl();

private:
  static sqlite3_stmt* prepare(sqlite3* conn, const std::string& sql);
  static std::vector<SEXPTYPE> get_initial_field_types(const int ncols);
  void init_if_bound();
  void init();

public:
  bool complete();
  int nrows();
  int rows_affected();
  IntegerVector find_params_impl(const CharacterVector& param_names);
  void bind_impl(const List& params);
  void bind_rows_impl(const List& params);
  List fetch_impl(const int n_max);
  List get_column_info_impl();

private:
  void bind_parameter(int i, int j, const std::string& name, SEXP values_);
  int find_parameter(const std::string& name);
  void bind_parameter_pos(int i, int j, SEXP value_);

  List fetch_rows(int n_max, int& n);
  void step();
  List peek_first_row();
  List alloc_missing_cols(List data, int n);

  void set_col_values(List& out, const int i, const int n);
  void set_col_value(SEXP& col, const int i, const int j, const int n);
  SEXP alloc_col(const unsigned int type, const int i, const int n);
  void fill_default_col_value(SEXP col, const int i);
  void fill_col_value(const SEXP col, const int i, const int j);

  void set_int_value(const SEXP col, const int i, const int j) const;
  void set_real_value(const SEXP col, const int i, const int j) const;
  void set_string_value(const SEXP col, const int i, const int j) const;
  void set_raw_value(SEXP col, const int i, const int j) const ;

  static unsigned int datatype_to_sexptype(const int field_type);
  static unsigned int decltype_to_sexptype(const char* decl_type);

  void raise_sqlite_exception() const;
  static void raise_sqlite_exception(sqlite3* conn);
};


#endif //RSQLITE_SQLITERESULTIMPL_H
