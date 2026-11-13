#include <cpp11.hpp>
#include "pch.h"
#include "SqliteResultImpl.h"
#include "SqliteArrowColumn.h"
#include "SqliteDataFrame.h"
#include "DbColumnStorage.h"
#include "DbConnection.h"
#include "SqliteParamSource.h"
#include <cstdint>
#include <stdexcept>

namespace {

// An error of a step, from SQLite or from a parameter that cannot be bound,
// with SQLite's result code; SQLITE_ERROR for a parameter.
// It leaves the C++ code only through cpp11's entry points,
// which turn it into an R error with its message,
// so that read_ahead() can keep it for the next fetch instead.
class step_error : public std::runtime_error {
public:
  step_error(const std::string& message, int code)
      : std::runtime_error(message), code_(code) {}

  int code() const {
    return code_;
  }

private:
  int code_;
};

// The struct type of the Arrow chunks of `columns`
void set_struct_schema(
  const boost::ptr_vector<SqliteArrowColumn>& columns,
  struct ArrowSchema* schema
) {
  nanoarrow::UniqueSchema out;
  ArrowSchemaInit(out.get());
  check_arrow(
    ArrowSchemaSetTypeStruct(out.get(), static_cast<int64_t>(columns.size())),
    "Can't allocate Arrow schema"
  );
  for (size_t j = 0; j < columns.size(); ++j) {
    columns[j].set_schema(out->children[j]);
  }
  out.move(schema);
}

// The rows of an Arrow chunk, built column by column, see fetch_loop()
class ArrowChunk {
  boost::ptr_vector<SqliteArrowColumn>& columns_;
  const int n_max_;
  // The rows of the result before this chunk
  const int64_t offset_;
  // The most bytes of text or blobs in a utf8 or binary column
  const int64_t max_bytes_;
  // Set while the columns hold the storage classes of the current row
  bool& row_read_;
  int i_;

public:
  ArrowChunk(
    boost::ptr_vector<SqliteArrowColumn>& columns,
    const int n_max,
    const int64_t offset,
    const int64_t max_bytes,
    bool& row_read
  )
      : columns_(columns),
        n_max_(n_max),
        offset_(offset),
        max_bytes_(max_bytes),
        row_read_(row_read),
        i_(0) {
    for (size_t j = 0; j < columns_.size(); ++j) {
      columns_[j].start_chunk();
    }
  }

  // Whether the chunk takes the current row: not if one of its values would
  // take the data of a utf8 or binary column beyond `max_bytes_`.
  // The statement then stays on the row, which starts the next chunk.
  // A value beyond them on its own fails the chunk that it starts,
  // so that the rows before it come out first.
  bool takes_row() {
    // The storage classes are read before anything converts the values,
    // and kept for the next chunk when this one doesn't take the row
    if (!row_read_) {
      for (size_t j = 0; j < columns_.size(); ++j) {
        columns_[j].read_type();
      }
      row_read_ = true;
    }
    // The bytes are read anew in each chunk:
    // reading the row as a data frame meanwhile may have moved them
    for (size_t j = 0; j < columns_.size(); ++j) {
      if (!columns_[j].read_bytes(max_bytes_)) {
        if (i_ == 0) {
          columns_[j].stop_too_long(max_bytes_);
        }
        return false;
      }
    }
    return true;
  }

  void set_col_values() {
    // The 1-based row number in the result, for the logs of the columns
    const int64_t row = offset_ + i_ + 1;
    for (size_t j = 0; j < columns_.size(); ++j) {
      columns_[j].append_row(row);
    }
  }

  bool advance() {
    ++i_;

    if (i_ % 1024 == 0) {
      cpp11::check_user_interrupt();
    }

    return (n_max_ < 0 || i_ < n_max_);
  }

  // Moves the chunk and its schema to `array` and `schema` once both are
  // complete; the types of the columns are final from then on
  void finish(struct ArrowArray* array, struct ArrowSchema* schema) {
    const int64_t ncols = static_cast<int64_t>(columns_.size());
    for (size_t j = 0; j < columns_.size(); ++j) {
      columns_[j].finish_chunk(i_);
    }

    nanoarrow::UniqueSchema out_schema;
    set_struct_schema(columns_, out_schema.get());

    nanoarrow::UniqueArray out;
    check_arrow(
      ArrowArrayInitFromType(out.get(), NANOARROW_TYPE_STRUCT),
      "Can't allocate Arrow array"
    );
    check_arrow(
      ArrowArrayAllocateChildren(out.get(), ncols),
      "Can't allocate Arrow array"
    );
    for (size_t j = 0; j < columns_.size(); ++j) {
      columns_[j].move_chunk_to(out->children[j]);
    }
    out->length = i_;
    out->null_count = 0;

    struct ArrowError error;
    ArrowErrorInit(&error);
    check_arrow(
      ArrowArrayFinishBuildingDefault(out.get(), &error),
      "Can't finish Arrow array",
      &error
    );

    for (size_t j = 0; j < columns_.size(); ++j) {
      columns_[j].freeze();
    }
    out.move(array);
    out_schema.move(schema);
  }
};

}  // namespace

// The chunk of an Arrow fetch until it is handed out, see fetch_arrow_chunk()
struct KeptArrowChunk {
  nanoarrow::UniqueArray array;
  nanoarrow::UniqueSchema schema;
};

// Construction ////////////////////////////////////////////////////////////////

SqliteResultImpl::SqliteResultImpl(
  const DbConnectionPtr& conn_,
  const std::string& sql
)
    : conn(conn_->conn()),
      stmt(prepare(conn, sql)),
      connection_(conn_.get()),
      cache(stmt),
      complete_(false),
      ready_(false),
      bind_started_(false),
      nrows_(0),
      total_changes_start_(sqlite3_total_changes(conn)),
      types_(get_initial_field_types(cache.ncols_)),
      with_alt_types_(conn_->with_alt_types()),
      error_kept_(false),
      kept_error_code_(SQLITE_OK),
      arrow_row_read_(false),
      arrow_max_bytes_(INT32_MAX),
      executions_(0) {
  try {
    if (cache.nparams_ == 0) {
      after_bind(true);
    }
  } catch (...) {
    sqlite3_finalize(stmt);
    stmt = NULL;
    throw;
  }
}

SqliteResultImpl::~SqliteResultImpl() {
  try {
    sqlite3_finalize(stmt);
  } catch (...) {}
}

// Cache ///////////////////////////////////////////////////////////////////////

SqliteResultImpl::_cache::_cache(sqlite3_stmt* stmt)
    : names_(get_column_names(stmt)),
      ncols_(names_.size()),
      nparams_(sqlite3_bind_parameter_count(stmt)) {}

std::vector<std::string> SqliteResultImpl::_cache::get_column_names(
  sqlite3_stmt* stmt
) {
  int ncols = sqlite3_column_count(stmt);

  std::vector<std::string> names;
  for (int j = 0; j < ncols; ++j) {
    names.push_back(sqlite3_column_name(stmt, j));
  }

  return names;
}

// We guess the correct R type for each column from the declared column type,
// if possible.  The type of the column can be amended as new values come in,
// but will be fixed after the first call to fetch().
std::vector<DATA_TYPE> SqliteResultImpl::get_initial_field_types(
  const size_t ncols
) {
  std::vector<DATA_TYPE> types(ncols);
  std::fill(types.begin(), types.end(), DT_UNKNOWN);
  return types;
}

sqlite3_stmt* SqliteResultImpl::prepare(sqlite3* conn, const std::string& sql) {
  sqlite3_stmt* stmt = NULL;

  const char* tail = NULL;

  int rc = sqlite3_prepare_v2(
    conn,
    sql.c_str(),
    (int)std::min(sql.size() + 1, (size_t)INT_MAX),
    &stmt,
    &tail
  );
  if (rc != SQLITE_OK) {
    raise_sqlite_exception(conn);
  }
  if (tail) {
    while (isspace(*tail)) {
      ++tail;
    }
    if (*tail) {
      cpp11::warning(std::string("Ignoring remaining part of query: ") + tail);
    }
  }

  return stmt;
}

void SqliteResultImpl::init(bool params_have_rows) {
  ready_ = true;
  nrows_ = 0;
  complete_ = !params_have_rows;
}

// Publics /////////////////////////////////////////////////////////////////////

void SqliteResultImpl::close() {}

// The rows of a kept Arrow chunk count once it is handed out,
// see fetch_arrow_chunk()
bool SqliteResultImpl::complete() const {
  return complete_ && !arrow_chunk_kept();
}

int SqliteResultImpl::n_rows_fetched() {
  if (arrow_chunk_kept()) {
    return nrows_ - static_cast<int>(arrow_chunk_->array->length);
  }
  return nrows_;
}

int SqliteResultImpl::n_rows_affected() {
  // Changes count from the latest bind, also if it failed partway
  if (!ready_ && !bind_started_) {
    return NA_INTEGER;
  }
  return sqlite3_total_changes(conn) - total_changes_start_;
}

void SqliteResultImpl::bind(const cpp11::list& params) {
  check_param_count(params.size());
  start_bind(new SqliteListParamSource(params));
}

void SqliteResultImpl::bind_arrow(
  struct ArrowArrayStream* stream,
  const std::vector<int>& indexes
) {
  check_param_count(static_cast<R_xlen_t>(indexes.size()));
  // The source checks the types of the parameters
  // before the previous bind is dropped,
  // so that a type that can't be bound leaves the result as it was
  start_bind(new SqliteArrowParamSource(stream, indexes));
}

void SqliteResultImpl::check_param_count(R_xlen_t n) const {
  if (cache.nparams_ == 0) {
    cpp11::stop("Query does not require parameters.");
  }

  if (n != cache.nparams_) {
    cpp11::stop(
      "Query requires %i params; %i supplied.",
      cache.nparams_,
      static_cast<int>(n)
    );
  }
}

// Takes `params` over, and executes the statement for its first set
void SqliteResultImpl::start_bind(SqliteParamSource* params) {
  params_.reset(params);
  ++executions_;
  // A new execution decides its Arrow types anew,
  // and drops a chunk kept from the previous one
  arrow_columns_.clear();
  arrow_chunk_.reset();

  total_changes_start_ = sqlite3_total_changes(conn);
  bind_started_ = true;

  // A new execution starts: the error kept from the previous one is dropped
  error_kept_ = false;
  kept_error_.clear();
  kept_error_code_ = SQLITE_OK;

  try {
    bool has_params = bind_row();
    after_bind(has_params);
  } catch (...) {
    // Parameters that fail to bind or to execute leave the result unbound:
    // fetching asks for a new bind instead of running them again,
    // while dbGetRowsAffected() counts from this bind
    params_.reset();
    ready_ = false;
    complete_ = false;
    nrows_ = 0;
    throw;
  }
}

cpp11::list SqliteResultImpl::fetch(const int n_max) {
  if (!ready_) {
    cpp11::stop("Query needs to be bound before fetching");
  }
  if (arrow_chunk_kept()) {
    // Its rows would come after those of this fetch
    cpp11::stop(
      "Can't fetch a data frame before the Arrow chunk that was kept "
      "when the warning about its values exited."
    );
  }

  int n = 0;
  cpp11::list out;

  if (n_max != 0) {
    out = fetch_rows(n_max, n);
  } else {
    out = peek_first_row();
  }

  return out;
}

void SqliteResultImpl::fetch_arrow_chunk(
  struct ArrowArray* array,
  struct ArrowSchema* schema,
  const int n_max
) {
  // A chunk kept when its warning exited,
  // or by arrow_schema(), comes first, whatever `n_max`,
  // and without warning again
  if (!arrow_chunk_kept()) {
    build_arrow_chunk(n_max);
  }

  arrow_chunk_->array.move(array);
  arrow_chunk_->schema.move(schema);
}

void SqliteResultImpl::arrow_schema(
  struct ArrowSchema* schema,
  const int n_max
) {
  // The first chunk decides the types,
  // and is kept for the next fetch
  if (!arrow_chunk_kept() && !arrow_types_decided()) {
    build_arrow_chunk(n_max);
  }

  if (arrow_chunk_kept()) {
    check_arrow(
      ArrowSchemaDeepCopy(arrow_chunk_->schema.get(), schema),
      "Can't copy Arrow schema"
    );
  } else {
    set_struct_schema(arrow_columns_, schema);
  }
}

int SqliteResultImpl::executions() const {
  return executions_;
}

void SqliteResultImpl::build_arrow_chunk(const int n_max) {
  if (!ready_) {
    throw std::runtime_error("Query needs to be bound before fetching");
  }

  if (!arrow_chunk_) {
    arrow_chunk_.reset(new KeptArrowChunk());
  }

  if (arrow_columns_.empty()) {
    for (size_t j = 0; j < cache.ncols_; ++j) {
      arrow_columns_.push_back(new SqliteArrowColumn(
        stmt,
        static_cast<int>(j),
        cache.names_[j],
        with_alt_types_
      ));
    }
  }

  ArrowChunk
    chunk(arrow_columns_, n_max, nrows_, arrow_max_bytes_, arrow_row_read_);
  fetch_loop(chunk, n_max, [&] {
    chunk.finish(arrow_chunk_->array.get(), arrow_chunk_->schema.get());
  });

  // The warning comes once the chunk is complete and the fetch loop is left,
  // while the result stays busy, see run_guarded() in DbResult.cpp.
  // Its handlers can't find a chunk half-built,
  // and an error made of the warning, as with options(warn = 2),
  // or a handler that exits leaves the result as it is:
  // the chunk is kept and comes with the next fetch.
  warn_arrow_coercions();
}

cpp11::list SqliteResultImpl::get_column_info() {
  using namespace cpp11::literals;
  peek_first_row();

  cpp11::writable::strings names(cache.names_.size());
  auto it = cache.names_.begin();
  for (int i = 0; i < names.size(); i++, it++) {
    names[i] = *it;
  }

  cpp11::writable::strings types(cache.ncols_);
  for (size_t i = 0; i < cache.ncols_; i++) {
    switch (types_[i]) {
    case DT_DATE:
      types[i] = "Date";
      break;
    case DT_DATETIME:
      types[i] = "POSIXct";
      break;
    case DT_TIME:
      types[i] = "hms";
      break;
    default:
      types[i] =
        Rf_type2char(DbColumnStorage::sexptype_from_datatype(types_[i]));
      break;
    }
  }

  return cpp11::list({ "name"_nm = names, "type"_nm = types });
}

// Publics (custom) ////////////////////////////////////////////////////////////

void SqliteResultImpl::set_arrow_max_bytes(int64_t max_bytes) {
  arrow_max_bytes_ = max_bytes;
}

cpp11::strings SqliteResultImpl::get_placeholder_names() const {
  int n = sqlite3_bind_parameter_count(stmt);

  cpp11::writable::strings res(n);

  for (int i = 0; i < n; ++i) {
    const char* placeholder_name = sqlite3_bind_parameter_name(stmt, i + 1);
    if (placeholder_name == NULL) {
      placeholder_name = "";
    } else {
      ++placeholder_name;
    }
    res[i] = placeholder_name;
  }

  return res;
}

// Privates ////////////////////////////////////////////////////////////////////

// Binds the next parameter set, if any.
// A value that can't be bound fails like a step, with SQLITE_ERROR:
// the error of a later set stays for the next fetch, see read_ahead().
bool SqliteResultImpl::bind_row() {
  if (!params_) {
    return false;
  }

  try {
    return params_->bind_next_row(stmt);
  } catch (const std::runtime_error& e) {
    throw step_error(e.what(), SQLITE_ERROR);
  }
}

void SqliteResultImpl::after_bind(bool params_have_rows) {
  init(params_have_rows);
  if (params_have_rows) {
    step();
  }
}

cpp11::list SqliteResultImpl::fetch_rows(const int n_max, int& n) {
  n = (n_max < 0) ? 100 : n_max;

  SqliteDataFrame data(stmt, cache.names_, n_max, types_, with_alt_types_);

  if (complete_ && data.get_ncols() == 0) {
    // Through cpp11, so that an error made of it unwinds the C++ frames
    cpp11::warning(
      "%s",
      "`dbGetQuery()`, `dbSendQuery()` and `dbFetch()` should only be used "
      "with `SELECT` queries. Did you mean `dbExecute()`, `dbSendStatement()` "
      "or `dbGetRowsAffected()`?"
    );
  }

  cpp11::list out;
  fetch_loop(data, n_max, [&] { out = data.get_data(types_); });
  return out;
}

// Reads rows into `rows` until `n_max` rows, all of them if negative,
// or the end of the result, and completes them with `finish()`.
// `rows` tells with takes_row() whether it takes the current row,
// appends it with set_col_values(),
// and tells with advance() whether it takes another one,
// as SqliteDataFrame and ArrowChunk do.
// A row that it doesn't take stays the current one, for the next fetch.
template <typename Rows, typename Finish>
void SqliteResultImpl::fetch_loop(Rows& rows, const int n_max, Finish finish) {
  // Rows count as fetched once they are returned, not if the fetch fails,
  // also not if the conversion fails
  int n_fetched = 0;
  try {
    // The step past the rows of the previous fetch failed
    if (error_kept_) {
      raise_kept_error();
    }

    while (!complete_) {
      if (!rows.takes_row()) {
        break;
      }
      rows.set_col_values();
      // The step past the last row of a full fetch only reads ahead
      if (++n_fetched == n_max) {
        read_ahead();
      } else {
        step();
      }
      if (!rows.advance()) {
        break;
      }
    }

    finish();
  } catch (...) {
    // An error that unwinds through the C++ frames of a fetch ends the
    // execution: a failed step or a kept error, an error that the conversion
    // raises through cpp11 or that building the Arrow arrays throws,
    // a warning raised through cpp11 that becomes an error
    // or that a handler leaves the fetch on, or an interrupt.
    // Stepping again would silently restart a statement that failed,
    // and fetching again would convert the same value again
    // or go on after the rows of this fetch.
    // Resetting the statement ends it, so that it releases its read lock.
    // The statement is still there: a handler can't clear the result while
    // the fetch runs, see run_guarded() in DbResult.cpp.
    // An R error that longjmps past these frames, such as a failed allocation
    // in R's API while values are read, skips this: the result stays
    // incomplete, and the next fetch goes on after the rows that were lost.
    complete_ = true;
    error_kept_ = false;
    kept_error_.clear();
    kept_error_code_ = SQLITE_OK;
    sqlite3_reset(stmt);
    throw;
  }

  nrows_ += n_fetched;
}

// A failed step ends the execution for every caller, and its error,
// a step_error, reaches R at the entry point:
// stepping again would silently restart a statement that failed
void SqliteResultImpl::step() {
  try {
    while (step_run())
      ;
  } catch (...) {
    complete_ = true;
    throw;
  }
}

// Steps past the last row of a full fetch.
// This step only tells whether the result is complete,
// and finishes the statement if it is, so that it releases its locks.
// An error is kept for the next fetch instead of costing the rows of this one;
// SQLite's message and result code are saved now,
// before later calls overwrite them.
// The Arrow columns read the storage classes of the row read ahead at once,
// and keep them for the next Arrow fetch, as for a row that a chunk held back:
// reading the row as a data frame meanwhile can convert its values.
void SqliteResultImpl::read_ahead() {
  try {
    while (step_run())
      ;
  } catch (const step_error& e) {
    error_kept_ = true;
    kept_error_ = e.what();
    kept_error_code_ = e.code();
    return;
  }
  if (complete_ || arrow_columns_.empty()) {
    return;
  }
  for (size_t j = 0; j < arrow_columns_.size(); ++j) {
    arrow_columns_[j].read_type();
  }
  arrow_row_read_ = true;
}

bool SqliteResultImpl::step_run() {
  // The next row has storage classes of its own
  arrow_row_read_ = false;
  int rc = sqlite3_step(stmt);

  switch (rc) {
  case SQLITE_DONE:
    return step_done();
  case SQLITE_ROW:
    return false;
  default:
    // sqlite3_errmsg() of a closed handle only reports API misuse
    throw step_error(
      connection_->is_closed() ? sqlite3_errstr(rc) : sqlite3_errmsg(conn),
      rc
    );
  }
}

bool SqliteResultImpl::step_done() {
  bool more_params = bind_row();

  if (!more_params) {
    complete_ = true;
  }

  return more_params;
}

cpp11::list SqliteResultImpl::peek_first_row() {
  SqliteDataFrame data(stmt, cache.names_, 1, types_, with_alt_types_);

  // After a failed step, the statement is on no row:
  // the kept error is left for the next fetch that reads rows.
  // An error while converting the row leaves the result as it is,
  // because peeking reads no row.
  if (!complete_ && !error_kept_) {
    data.set_col_values();
  }
  // Not calling data.advance(), remains a zero-row data frame

  return data.get_data(types_);
}

bool SqliteResultImpl::arrow_chunk_kept() const {
  return arrow_chunk_ && arrow_chunk_->array->release != NULL;
}

const struct ArrowArrayStream* SqliteResultImpl::arrow_param_stream() const {
  const SqliteArrowParamSource* source =
    dynamic_cast<const SqliteArrowParamSource*>(params_.get());
  return source != NULL ? source->get_stream() : NULL;
}

// A chunk of the current execution has fixed the Arrow types
bool SqliteResultImpl::arrow_types_decided() const {
  return !arrow_columns_.empty() && arrow_columns_[0].is_frozen();
}

// One warning for the values of the latest Arrow chunk that didn't fit
// the type of their column, through warn_coercion() in R;
// nothing if there were none
void SqliteResultImpl::warn_arrow_coercions() {
  std::vector<cpp11::sexp> columns;
  for (size_t j = 0; j < arrow_columns_.size(); ++j) {
    cpp11::sexp coercions = arrow_columns_[j].take_coercions();
    if (coercions != R_NilValue) {
      columns.push_back(coercions);
    }
  }
  if (columns.empty()) {
    return;
  }

  cpp11::writable::list entries(static_cast<R_xlen_t>(columns.size()));
  for (size_t k = 0; k < columns.size(); ++k) {
    entries[k] = columns[k];
  }
  cpp11::function warn_coercion = cpp11::package("RSQLite")["warn_coercion"];
  warn_coercion(entries);
}

void SqliteResultImpl::raise_kept_error() {
  step_error error(kept_error_, kept_error_code_);
  error_kept_ = false;
  kept_error_.clear();
  kept_error_code_ = SQLITE_OK;
  throw error;
}

// Throws a C++ exception rather than an R error: cpp11 turns it into an R error
// at the entry point, with the message as it is, not as a format string.
void SqliteResultImpl::raise_sqlite_exception(sqlite3* conn) {
  throw std::runtime_error(sqlite3_errmsg(conn));
}
