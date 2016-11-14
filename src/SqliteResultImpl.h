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
  List params_;
  int group_, groups_;
  std::vector<SEXPTYPE> types_;

public:
  SqliteResultImpl(sqlite3* conn_, const std::string& sql);
  ~SqliteResultImpl();

private:
  static sqlite3_stmt* prepare(sqlite3* conn, const std::string& sql);
  static std::vector<SEXPTYPE> get_initial_field_types(const int ncols);
  void after_bind(bool params_have_rows);
  void init(bool params_have_rows);

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
  void set_params(const List& params);
  bool bind_row();
  void bind_parameter(int j, const std::string& name, SEXP values_);
  int find_parameter(const std::string& name);
  void bind_parameter_pos(int j, SEXP value_);

  List fetch_rows(int n_max, int& n);
  void step();
  bool step_run();
  bool step_done();
  List peek_first_row();

  void NORET raise_sqlite_exception() const;
  static void NORET raise_sqlite_exception(sqlite3* conn);
};


#endif //RSQLITE_SQLITERESULTIMPL_H
