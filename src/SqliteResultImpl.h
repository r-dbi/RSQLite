#ifndef RSQLITE_SQLITERESULTIMPL_H
#define RSQLITE_SQLITERESULTIMPL_H

#include <cpp11.hpp>
#include <boost/noncopyable.hpp>
#include <boost/ptr_container/ptr_vector.hpp>
#include <boost/scoped_ptr.hpp>
#include <boost/shared_ptr.hpp>
#include "sqlite3-cpp.h"
#include "DbColumnDataType.h"

class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;
class SqliteParamSource;
// Declared only, so that the files that include this header
// don't compile the nanoarrow headers
class SqliteArrowColumn;
struct ArrowArray;
struct ArrowSchema;
struct ArrowArrayStream;
struct KeptArrowChunk;

class SqliteResultImpl : public boost::noncopyable {
private:
  // Wrapped pointer
  sqlite3* conn;
  sqlite3_stmt* stmt;
  // Kept alive by the DbResult that owns this object
  const DbConnection* connection_;

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
  // Set once a bind has started, also if it failed: see n_rows_affected()
  bool bind_started_;
  // 64 bits: a result read in chunks can pass INT_MAX rows,
  // and a statement can change as many
  int64_t nrows_;
  int64_t total_changes_start_;
  // The parameter sets of the latest bind, see bind_row()
  boost::scoped_ptr<SqliteParamSource> params_;
  std::vector<DATA_TYPE> types_;
  bool with_alt_types_;
  // The error of the step past the last row of a full fetch,
  // kept for the next fetch with SQLite's result code: see read_ahead()
  bool error_kept_;
  std::string kept_error_;
  int kept_error_code_;
  // The Arrow column types, decided by the first Arrow fetch of an execution,
  // see SqliteArrowColumn.
  // A data frame fetch types its columns on its own, see types_.
  boost::ptr_vector<SqliteArrowColumn> arrow_columns_;
  // The latest Arrow chunk until it is handed out,
  // kept when the warning about its values exits: see fetch_arrow_chunk()
  boost::scoped_ptr<KeptArrowChunk> arrow_chunk_;
  // Set while the Arrow columns hold the storage classes of the current row,
  // also when a chunk ended before it or a fetch read it ahead:
  // see ArrowChunk::takes_row() and read_ahead()
  bool arrow_row_read_;
  // The most bytes of text or blobs in a utf8 or binary column of a chunk,
  // the 2^31 - 1 that their 32-bit offsets address unless a test lowers them
  int64_t arrow_max_bytes_;
  // Counts the binds, so that an Arrow stream can tell that the rows of the
  // execution that it reads are gone, see SqliteArrowStream.cpp
  int executions_;

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
  // Binds the rows of an Arrow array stream of struct arrays,
  // taking child `indexes[k]` for placeholder k + 1,
  // see SqliteArrowParamSource
  void bind_arrow(
    struct ArrowArrayStream* stream,
    const std::vector<int>& indexes
  );
  cpp11::list fetch(const int n_max);
  // Fetches at most `n_max` rows, all of them if negative, into a struct array,
  // and warns about the values converted to the type of their column;
  // hands out a chunk kept when its warning exited instead, whole,
  // whatever `n_max`.
  // The chunk ends before a row whose text or blobs would take a utf8 or
  // binary column beyond `arrow_max_bytes_`, and the next one starts with it.
  void fetch_arrow_chunk(
    struct ArrowArray* array,
    struct ArrowSchema* schema,
    const int n_max
  );

  // The struct type of the Arrow chunks of the current execution.
  // Unless an Arrow fetch has decided it already,
  // the first chunk of at most `n_max` rows decides it now,
  // and is kept for the next Arrow fetch, as a chunk whose warning exited.
  void arrow_schema(struct ArrowSchema* schema, const int n_max);
  int executions() const;
  bool arrow_chunk_kept() const;
  // The Arrow stream bound as parameters, if any
  const struct ArrowArrayStream* arrow_param_stream() const;

  cpp11::list get_column_info();

public:
  // For the tests, see result_set_arrow_max_bytes()
  void set_arrow_max_bytes(int64_t max_bytes);
  cpp11::strings get_placeholder_names() const;

private:
  void check_param_count(R_xlen_t n) const;
  void start_bind(SqliteParamSource* params);
  bool bind_row();
  void after_bind(bool params_have_rows);

  cpp11::list fetch_rows(int n_max, int& n);
  template <typename Rows, typename Finish>
  void fetch_loop(Rows& rows, int n_max, Finish finish);
  void step();
  void read_ahead();
  bool step_run();
  bool step_done();
  cpp11::list peek_first_row();
  void build_arrow_chunk(const int n_max);
  bool arrow_types_decided() const;
  void warn_arrow_coercions();

private:
  NORET void raise_kept_error();
  NORET static void raise_sqlite_exception(sqlite3* conn);
};

#endif  // RSQLITE_SQLITERESULTIMPL_H
