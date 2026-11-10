#ifndef RSQLITE_SQLITERESULTIMPL_H
#define RSQLITE_SQLITERESULTIMPL_H

#include <cpp11.hpp>
#include <boost/noncopyable.hpp>
#include <boost/ptr_container/ptr_vector.hpp>
#include <boost/scoped_ptr.hpp>
#include <boost/shared_ptr.hpp>
#include <atomic>
#include <vector>
#include "sqlite3-cpp.h"
#include "DbArrow.h"
#include "DbColumnDataType.h"
#include "SqliteArrowColumn.h"
#include "SqliteParamSource.h"

class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;

// A value that one thread at a time writes, under the busy mark of the result,
// and that R's main thread reads at any time: dbGetRowCount() and
// dbHasCompleted() follow a stream read on another thread
template <typename T>
class ProgressValue {
  std::atomic<T> value_;

public:
  explicit ProgressValue(T value) : value_(value) {}
  operator T() const {
    return value_.load(std::memory_order_acquire);
  }
  ProgressValue& operator=(T value) {
    value_.store(value, std::memory_order_release);
    return *this;
  }
  // Not an atomic increment: there is one writer at a time
  ProgressValue& operator++() {
    return *this = static_cast<T>(*this) + 1;
  }
};

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
  ProgressValue<bool> complete_;
  bool ready_;
  // 64 bits: an Arrow stream reads past INT_MAX rows
  ProgressValue<int64_t> nrows_;
  // Counts the executions with new parameters, see executions()
  int64_t executions_;
  int total_changes_start_;
  boost::scoped_ptr<SqliteParamSource> params_;
  std::vector<DATA_TYPE> types_;
  bool with_alt_types_;

  // Arrow state: the types requested for the columns, which outlive an
  // execution, the column types, decided once per execution, and a chunk
  // that had to be fetched to decide them before the schema was requested,
  // with the number of its rows already handed out
  std::vector<ArrowTarget> arrow_targets_;
  boost::ptr_vector<SqliteArrowColumn> arrow_columns_;
  bool arrow_frozen_;
  nanoarrow::UniqueArray pending_chunk_;
  int64_t pending_offset_;
  // The rows of that chunk not handed out yet, for n_rows_fetched()
  ProgressValue<int64_t> pending_rows_;
  // Set while the columns hold the storage classes of the current row,
  // also when a byte limit ended the chunk before it
  bool arrow_row_read_;
  // The types and 64-bit flags that the last data frame fetch left, which the
  // first one of a new execution starts from, like the default path does
  std::vector<ARROW_KIND> df_kinds_;
  std::vector<bool> df_wide_ints_;
  bool df_carry_;
  // The byte limits of utf8 and binary columns, see fetch_arrow_rows()
  int64_t arrow_cut_bytes_;
  int64_t arrow_max_bytes_;

public:
  SqliteResultImpl(const DbConnectionPtr& conn_, const std::string& sql);
  ~SqliteResultImpl();
  // Finalizes the statement early, on any thread
  void finalize_statement();

private:
  static sqlite3_stmt* prepare(sqlite3* conn, const std::string& sql);
  static std::vector<DATA_TYPE> get_initial_field_types(const size_t ncols);
  void init(bool params_have_rows);

public:
  void close();
  bool complete() const;
  bool ready() const;
  int64_t executions() const;
  int64_t n_rows_fetched();
  // For the tests
  void set_rows_fetched(int64_t n);
  int n_rows_affected();
  void bind(const cpp11::list& params);
  cpp11::list fetch(const int n_max);

  cpp11::list get_column_info();
  cpp11::strings get_column_names() const;

  // Arrow
  // `seconds` marks the times and timestamps that a data frame fetch stores
  // as doubles in seconds, see ArrowTarget
  void set_arrow_schema(
    const struct ArrowSchema* schema,
    const std::vector<int>& positions,
    const std::vector<bool>& seconds
  );
  void arrow_schema(struct ArrowSchema* out, int64_t infer_rows);
  int64_t fetch_arrow(struct ArrowArray* out, int64_t n_max);
  int64_t fetch_arrow_df(
    struct ArrowSchema* schema,
    std::vector<nanoarrow::UniqueArray>& chunks,
    ArrowDfColumns& columns,
    int64_t n_max,
    int64_t chunk_size
  );
  void bind_arrow(
    struct ArrowArrayStream* stream,
    const std::vector<int>& param_indexes
  );

public:
  cpp11::strings get_placeholder_names() const;

  // Sets the bytes of a utf8 or binary column after which, or beyond which,
  // fetch_arrow_rows() ends a chunk of this result; for the tests
  void set_arrow_bytes_limits(int64_t cut_bytes, int64_t max_bytes);

private:
  void after_set_params();
  bool bind_row();
  void after_bind(bool params_have_rows);

  cpp11::list fetch_rows(int n_max, int& n);
  void step();
  bool step_run();
  bool step_done();
  cpp11::list peek_first_row();

  void ensure_arrow_columns(bool data_frame);
  void freeze_arrow_columns();
  int64_t fetch_arrow_chunk(struct ArrowArray* out, int64_t n_max);
  int64_t fetch_arrow_rows(
    struct ArrowArray* out,
    int64_t n_max,
    std::vector<ARROW_KIND>* open_kinds = NULL
  );
  void set_arrow_struct_schema(struct ArrowSchema* out);
  void copy_pending_rows(struct ArrowArray* out, int64_t n);
  bool arrow_row_fits();
  bool arrow_chunk_full();
  cpp11::sexp collect_coercions();
  void warn_coercions();
  std::string coercions_text();
  void discard_coercions();

private:
  NORET void raise_sqlite_exception(int rc) const;
  NORET static void raise_sqlite_exception(sqlite3* conn);
};

#endif  // RSQLITE_SQLITERESULTIMPL_H
