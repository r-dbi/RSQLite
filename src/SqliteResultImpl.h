#ifndef RSQLITE_SQLITERESULTIMPL_H
#define RSQLITE_SQLITERESULTIMPL_H

#include <cpp11.hpp>
#include <boost/noncopyable.hpp>
#include <boost/ptr_container/ptr_vector.hpp>
#include <boost/scoped_ptr.hpp>
#include <boost/shared_ptr.hpp>
#include "sqlite3-cpp.h"
#include "DbArrow.h"
#include "DbColumnDataType.h"
#include "SqliteArrowColumn.h"
#include "SqliteParamSource.h"

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
  int nrows_;
  int total_changes_start_;
  boost::scoped_ptr<SqliteParamSource> params_;
  std::vector<DATA_TYPE> types_;
  bool with_alt_types_;

  // Arrow state: the column types, decided once per execution, and a chunk
  // that had to be fetched to decide them before the schema was requested
  boost::ptr_vector<SqliteArrowColumn> arrow_columns_;
  bool arrow_frozen_;
  nanoarrow::UniqueArray pending_chunk_;

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
  bool ready() const;
  int n_rows_fetched();
  int n_rows_affected();
  void bind(const cpp11::list& params);
  cpp11::list fetch(const int n_max);

  cpp11::list get_column_info();

  // Arrow
  void arrow_schema(struct ArrowSchema* out, int64_t infer_rows);
  int64_t fetch_arrow(struct ArrowArray* out, int64_t n_max);
  void bind_arrow(
    struct ArrowArrayStream* stream,
    const std::vector<int>& param_indexes
  );

public:
  cpp11::strings get_placeholder_names() const;

private:
  void after_set_params();
  bool bind_row();
  void after_bind(bool params_have_rows);

  cpp11::list fetch_rows(int n_max, int& n);
  void step();
  bool step_run();
  bool step_done();
  cpp11::list peek_first_row();

  void ensure_arrow_columns();
  void freeze_arrow_columns();
  int64_t fetch_arrow_rows(struct ArrowArray* out, int64_t n_max);

private:
  NORET void raise_sqlite_exception() const;
  NORET static void raise_sqlite_exception(sqlite3* conn);
};

#endif  // RSQLITE_SQLITERESULTIMPL_H
