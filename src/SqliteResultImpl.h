#ifndef RSQLITE_SQLITERESULTIMPL_H
#define RSQLITE_SQLITERESULTIMPL_H

#include <cpp11.hpp>
#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include "sqlite3-cpp.h"
#include "DbColumnDataType.h"

class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;

class SqliteResultImpl : public boost::noncopyable {
private:
  // Wrapped pointer
  sqlite3* conn;
  sqlite3_stmt* stmt;

  // Cache
  struct _cache {
    const std::vector<std::string> names_;
    const size_t ncols_;
    const int nparams_;

    _cache(sqlite3_stmt* stmt);

    static std::vector<std::string> get_column_names(sqlite3_stmt* stmt);
  } cache;

  // State
  bool complete_;
  bool ready_;
  // 64 bits: a result read in chunks can pass INT_MAX rows,
  // and a statement can change as many
  int64_t nrows_;
  int64_t total_changes_start_;
  cpp11::list params_;
  int group_, groups_;
  std::vector<DATA_TYPE> types_;
  bool with_alt_types_;
  // The error of the step past the last row of a full fetch,
  // kept for the next fetch with SQLite's result code: see read_ahead()
  bool error_kept_;
  // Whether raising the kept error completes the result
  bool kept_error_completes_;
  std::string kept_error_;
  int kept_error_code_;

public:
  SqliteResultImpl(const DbConnectionPtr& conn_, const std::string& sql);
  ~SqliteResultImpl();

private:
  static sqlite3_stmt* prepare(sqlite3* conn, const std::string& sql);
  static std::vector<DATA_TYPE> get_initial_field_types(const size_t ncols);
  void init(bool params_have_rows);

public:
  void close();
  bool complete() const;
  int64_t n_rows_fetched();
  int64_t n_rows_affected();
  // For the tests
  void set_rows_fetched(int64_t n);
  void set_rows_affected(int64_t n);
  void bind(const cpp11::list& params);
  cpp11::list fetch(const int n_max);

  cpp11::list get_column_info();

public:
  cpp11::strings get_placeholder_names() const;

private:
  void set_params(const cpp11::list& params);
  bool bind_row();
  void bind_parameter_pos(int j, SEXP value_);
  void after_bind(bool params_have_rows);

  cpp11::list fetch_rows(int n_max, int& n);
  void step();
  void read_ahead();
  bool step_run();
  bool step_done();
  cpp11::list peek_first_row();

private:
  NORET void raise_kept_error();
  NORET static void raise_sqlite_exception(sqlite3* conn);
  NORET void raise_bind_exception(int j, int rc);
};

#endif  // RSQLITE_SQLITERESULTIMPL_H
