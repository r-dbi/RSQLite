#include <cpp11.hpp>
#include "pch.h"
#include "SqliteResultImpl.h"
#include "SqliteDataFrame.h"
#include "DbColumnStorage.h"
#include "DbConnection.h"
#include "integer64.h"
#include <sstream>

// The data of a utf8 or binary column ends a chunk: after the row that takes
// it to `arrow_cut_bytes`, and before a row that would take it past
// `arrow_max_bytes`, the most that the 32-bit offsets of these types address.
// The tests lower both, see set_arrow_bytes_limits().
static int64_t arrow_cut_bytes = int64_t(1) << 30;
static int64_t arrow_max_bytes = INT32_MAX;

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
      nrows_(0),
      executions_(0),
      total_changes_start_(sqlite3_total_changes(conn)),
      types_(get_initial_field_types(cache.ncols_)),
      with_alt_types_(conn_->with_alt_types()),
      arrow_frozen_(false),
      pending_offset_(0),
      arrow_row_read_(false) {
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

// Rows kept from the chunk that decided the Arrow types count as fetched once
// they have been handed out

bool SqliteResultImpl::complete() const {
  return complete_ && pending_chunk_->release == NULL;
}

bool SqliteResultImpl::ready() const {
  return ready_;
}

int64_t SqliteResultImpl::executions() const {
  return executions_;
}

int SqliteResultImpl::n_rows_fetched() {
  int64_t kept = 0;
  if (pending_chunk_->release != NULL) {
    kept = pending_chunk_->length - pending_offset_;
  }
  return nrows_ - static_cast<int>(kept);
}

int SqliteResultImpl::n_rows_affected() {
  if (!ready_) {
    return NA_INTEGER;
  }
  return sqlite3_total_changes(conn) - total_changes_start_;
}

void SqliteResultImpl::bind(const cpp11::list& params) {
  if (cache.nparams_ == 0) {
    cpp11::stop("Query does not require parameters.");
  }

  if (params.size() != cache.nparams_) {
    cpp11::stop(
      "Query requires %i params; %i supplied.",
      cache.nparams_,
      params.size()
    );
  }

  params_.reset(new SqliteListParamSource(params));
  after_set_params();
}

cpp11::list SqliteResultImpl::fetch(const int n_max) {
  if (!ready_) {
    cpp11::stop("Query needs to be bound before fetching");
  }
  if (n_max != 0 && pending_chunk_->release != NULL) {
    // The statement has moved past them, a data frame can't include them
    cpp11::stop(
      "Rows fetched to decide the Arrow types are waiting, "
      "fetch them with `dbFetchArrowChunk()` or `dbFetchArrow()`."
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

// Arrow ///////////////////////////////////////////////////////////////////////

void SqliteResultImpl::arrow_schema(
  struct ArrowSchema* out,
  int64_t infer_rows
) {
  if (!ready_) {
    throw std::runtime_error("Query needs to be bound before fetching");
  }

  ensure_arrow_columns();

  if (!arrow_frozen_) {
    // The first chunk decides the types, from the first value of each column
    // that is not NULL, and is kept for the next fetch
    if (pending_chunk_->release == NULL && !complete_) {
      discard_coercions();
      nanoarrow::UniqueArray chunk;
      fetch_arrow_rows(chunk.get(), infer_rows);
      chunk.move(pending_chunk_.get());
    }
    // Columns that only ever held NULL take their declared type
    for (size_t j = 0; j < arrow_columns_.size(); ++j) {
      arrow_columns_[j].decide_from_decltype();
    }
    freeze_arrow_columns();

    // The rows have been read, the warning comes with the schema.
    // Last, with the chunk kept: if the warning is turned into an error,
    // a retry returns the schema and the rows wait for the next fetch.
    warn_coercions();
  }

  set_arrow_struct_schema(out);
}

int64_t SqliteResultImpl::fetch_arrow(struct ArrowArray* out, int64_t n_max) {
  discard_coercions();
  nanoarrow::UniqueArray chunk;
  int64_t n = fetch_arrow_chunk(chunk.get(), n_max);

  // One warning per chunk, before it is handed out: if the warning is turned
  // into an error, the chunk is released by the unwinding
  warn_coercions();

  chunk.move(out);
  return n;
}

// The next chunk for fetch_arrow(), without the warning
int64_t SqliteResultImpl::fetch_arrow_chunk(
  struct ArrowArray* out,
  int64_t n_max
) {
  if (!ready_) {
    throw std::runtime_error("Query needs to be bound before fetching");
  }

  ensure_arrow_columns();

  if (pending_chunk_->release != NULL) {
    int64_t n = std::min(
      pending_chunk_->length - pending_offset_,
      std::max(n_max, int64_t(0))
    );
    if (pending_offset_ == 0 && n == pending_chunk_->length) {
      pending_chunk_.move(out);
      return n;
    }

    // The chunk was fetched with a larger chunk size than this one:
    // its rows are handed out in copies of at most `n_max` rows
    copy_pending_rows(out, n);
    pending_offset_ += n;
    if (pending_offset_ == pending_chunk_->length) {
      pending_chunk_.reset();
      pending_offset_ = 0;
    }
    return n;
  }

  return fetch_arrow_rows(out, n_max);
}

// The rows of one dbFetch() through Arrow: at most `n_max` rows, all for a
// negative `n_max`, as chunks of at most `chunk_size` rows that share `schema`,
// with one warning for the values of all chunks that were not of their
// column's type.
// Unless an Arrow stream or chunk has fixed the types already, they are
// decided for this fetch like the default path decides them: a column that
// sees only NULL stays open across chunks, integers widen to double in any
// chunk, and the chunks are conformed to the final types at the end.
// A column without a value takes its declared type, or the null type, which
// the next fetch decides again; the other types carry over to the next fetch.
// `wide_ints` tells which columns have seen an integer that needs 64 bits,
// in this fetch or an earlier one.
int64_t SqliteResultImpl::fetch_arrow_df(
  struct ArrowSchema* schema,
  std::vector<nanoarrow::UniqueArray>& chunks,
  std::vector<bool>& wide_ints,
  int64_t n_max,
  int64_t chunk_size
) {
  if (!ready_) {
    throw std::runtime_error("Query needs to be bound before fetching");
  }

  ensure_arrow_columns();
  discard_coercions();
  const size_t ncols = arrow_columns_.size();
  const bool open = !arrow_frozen_;

  if (open && n_max == 0 && !complete_) {
    // A fetch of no rows types the columns from the next row,
    // like the default path does it
    if (!arrow_row_read_) {
      for (size_t j = 0; j < ncols; ++j) {
        arrow_columns_[j].read_row();
      }
      arrow_row_read_ = true;
    }
    for (size_t j = 0; j < ncols; ++j) {
      arrow_columns_[j].peek_value();
    }
  }

  // The type of each column in each chunk, while the types are open
  std::vector<std::vector<ARROW_KIND> > kinds;
  int64_t total = 0;
  while ((n_max < 0 || total < n_max) && !complete()) {
    int64_t n_chunk = chunk_size;
    if (n_max >= 0) {
      n_chunk = std::min(chunk_size, n_max - total);
    }

    nanoarrow::UniqueArray chunk;
    int64_t n;
    if (open) {
      kinds.push_back(std::vector<ARROW_KIND>());
      n = fetch_arrow_rows(chunk.get(), n_chunk, &kinds.back());
    } else {
      n = fetch_arrow_chunk(chunk.get(), n_chunk);
    }
    if (n == 0) {
      // Not reached: only the end of the result gives an empty chunk
      if (open) {
        kinds.pop_back();
      }
      break;
    }

    total += n;
    chunks.push_back(std::move(chunk));
  }

  if (open) {
    for (size_t j = 0; j < ncols; ++j) {
      arrow_columns_[j].decide_from_decltype();
    }
  }

  set_arrow_struct_schema(schema);

  if (open) {
    for (size_t i = 0; i < chunks.size(); ++i) {
      for (size_t j = 0; j < ncols; ++j) {
        arrow_columns_[j].conform_chunk(chunks[i]->children[j], kinds[i][j]);
      }
    }
    for (size_t j = 0; j < ncols; ++j) {
      arrow_columns_[j].reopen();
    }
  }

  wide_ints.clear();
  for (size_t j = 0; j < ncols; ++j) {
    wide_ints.push_back(arrow_columns_[j].wide_integers());
  }

  // One warning for the whole fetch, with the final types: a column logged
  // as int64 may have become double since. A column that reopen() let go of
  // the null type held no values, so has no entries.
  // Last, so that an error raised from the warning leaves the result ready
  // for the next fetch; the caller owns the chunks, the unwinding releases
  // them.
  warn_coercions();

  return total;
}

void SqliteResultImpl::bind_arrow(
  struct ArrowArrayStream* stream,
  const std::vector<int>& param_indexes
) {
  if (cache.nparams_ == 0) {
    throw std::runtime_error("Query does not require parameters.");
  }

  if (param_indexes.size() != static_cast<size_t>(cache.nparams_)) {
    std::stringstream ss;
    ss << "Query requires " << cache.nparams_ << " params; "
       << param_indexes.size() << " supplied.";
    throw std::runtime_error(ss.str());
  }

  params_.reset(new SqliteArrowParamSource(stream, param_indexes));
  try {
    after_set_params();
  } catch (...) {
    // A stream that fails on its first row is not kept: it may hold a share
    // of this result, through a stream that wraps one of its Arrow streams
    params_.reset();
    throw;
  }
}

// Publics (custom) ////////////////////////////////////////////////////////////

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

void SqliteResultImpl::after_set_params() {
  ++executions_;

  // A new execution may see other values in the first row
  arrow_columns_.clear();
  arrow_frozen_ = false;
  pending_chunk_.reset();
  pending_offset_ = 0;
  arrow_row_read_ = false;

  total_changes_start_ = sqlite3_total_changes(conn);

  bool has_params = bind_row();
  after_bind(has_params);
}

bool SqliteResultImpl::bind_row() {
  if (!params_) {
    return false;
  }

  return params_->bind_next_row(stmt);
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
    Rf_warning(
      "`dbGetQuery()`, `dbSendQuery()` and `dbFetch()` should only be used "
      "with `SELECT` queries. Did you mean `dbExecute()`, `dbSendStatement()` "
      "or `dbGetRowsAffected()`?"
    );
  }

  while (!complete_) {
    data.set_col_values();
    step();
    nrows_++;
    if (!data.advance()) {
      break;
    }
  }

  return data.get_data(types_);
}

void SqliteResultImpl::step() {
  // The next row has storage classes of its own
  arrow_row_read_ = false;
  while (step_run())
    ;
}

bool SqliteResultImpl::step_run() {
  int rc = sqlite3_step(stmt);

  switch (rc) {
  case SQLITE_DONE:
    return step_done();
  case SQLITE_ROW:
    return false;
  default:
    raise_sqlite_exception(rc);
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

  if (!complete_) {
    data.set_col_values();
  }
  // Not calling data.advance(), remains a zero-row data frame

  return data.get_data(types_);
}

void SqliteResultImpl::ensure_arrow_columns() {
  if (!arrow_columns_.empty() || cache.ncols_ == 0) {
    return;
  }

  // A row is available unless the query is complete
  bool has_row = !complete_;
  for (size_t j = 0; j < cache.ncols_; ++j) {
    SqliteArrowColumn* column = new SqliteArrowColumn(
      stmt,
      static_cast<int>(j),
      cache.names_[j],
      with_alt_types_
    );
    column->decide_from_row(has_row);
    arrow_columns_.push_back(column);
  }
}

void SqliteResultImpl::freeze_arrow_columns() {
  for (size_t j = 0; j < arrow_columns_.size(); ++j) {
    arrow_columns_[j].freeze();
  }
  arrow_frozen_ = true;
}

// The next chunk of at most `n_max` rows. The types are final from the first
// chunk on, unless `open_kinds` is given: then they stay open, as for a data
// frame, and `open_kinds` receives the type of each column in this chunk.
int64_t SqliteResultImpl::fetch_arrow_rows(
  struct ArrowArray* out,
  int64_t n_max,
  std::vector<ARROW_KIND>* open_kinds
) {
  const size_t ncols = arrow_columns_.size();

  for (size_t j = 0; j < ncols; ++j) {
    arrow_columns_[j].start_chunk();
  }

  int64_t n = 0;
  while (!complete_ && n < n_max) {
    // The storage classes are read once per row, before any conversion.
    // A row that a byte limit held back from the previous chunk keeps them:
    // the check converted some of its values.
    if (!arrow_row_read_) {
      for (size_t j = 0; j < ncols; ++j) {
        arrow_columns_[j].read_row();
      }
      arrow_row_read_ = true;
    }
    // A row that would overflow a column starts the next chunk.
    // An empty chunk takes any row: sqlite3_column_bytes() returns an int,
    // so a single value never overflows.
    if (n > 0 && !arrow_row_fits()) {
      break;
    }

    // The 1-based row number in the result, for the coercion log
    const int64_t row = static_cast<int64_t>(nrows_) + 1;
    for (size_t j = 0; j < ncols; ++j) {
      arrow_columns_[j].append_row(row);
    }
    step();
    ++nrows_;
    ++n;

    if (n % 1024 == 0) {
      cpp11::check_user_interrupt();
    }
    if (arrow_chunk_full()) {
      break;
    }
  }

  for (size_t j = 0; j < ncols; ++j) {
    arrow_columns_[j].finish_chunk(n, open_kinds != NULL);
  }
  if (open_kinds == NULL) {
    freeze_arrow_columns();
  }

  nanoarrow::UniqueArray chunk;
  check_arrow(
    ArrowArrayInitFromType(chunk.get(), NANOARROW_TYPE_STRUCT),
    "Can't allocate Arrow array"
  );
  check_arrow(
    ArrowArrayAllocateChildren(chunk.get(), static_cast<int64_t>(ncols)),
    "Can't allocate Arrow array"
  );
  for (size_t j = 0; j < ncols; ++j) {
    ARROW_KIND kind = arrow_columns_[j].move_chunk_to(chunk->children[j]);
    if (open_kinds != NULL) {
      open_kinds->push_back(kind);
    }
  }
  chunk->length = n;
  chunk->null_count = 0;

  struct ArrowError error;
  ArrowErrorInit(&error);
  check_arrow(
    ArrowArrayFinishBuildingDefault(chunk.get(), &error),
    "Can't finish Arrow array",
    &error
  );

  chunk.move(out);
  return n;
}

// One warning for the values logged since the last call that were not of
// their column's type, naming the current types of the columns
void SqliteResultImpl::warn_coercions() {
  cpp11::writable::list entries;
  for (size_t j = 0; j < arrow_columns_.size(); ++j) {
    cpp11::sexp coercions = arrow_columns_[j].coercions();
    if (coercions != R_NilValue) {
      entries.push_back(coercions);
    }
  }
  if (entries.size() == 0) {
    return;
  }

  cpp11::function warn_coercion = cpp11::package("RSQLite")["warn_coercion"];
  warn_coercion(entries);
}

// A fetch that failed, by an error or an interrupt, leaves the values it
// logged: each fetch starts without them
void SqliteResultImpl::discard_coercions() {
  for (size_t j = 0; j < arrow_columns_.size(); ++j) {
    arrow_columns_[j].discard_coercions();
  }
}

void SqliteResultImpl::set_arrow_struct_schema(struct ArrowSchema* out) {
  ArrowSchemaInit(out);
  check_arrow(
    ArrowSchemaSetTypeStruct(out, static_cast<int64_t>(arrow_columns_.size())),
    "Can't allocate Arrow schema"
  );
  for (size_t j = 0; j < arrow_columns_.size(); ++j) {
    arrow_columns_[j].set_schema(out->children[j]);
  }
}

// Appends the value in row `i` of `values` to `out`, of the same type
static void append_arrow_value(
  struct ArrowArray* out,
  const struct ArrowArrayView* values,
  int64_t i
) {
  int code;
  if (ArrowArrayViewIsNull(values, i)) {
    code = ArrowArrayAppendNull(out, 1);
  } else {
    switch (values->storage_type) {
    case NANOARROW_TYPE_INT32:
    case NANOARROW_TYPE_INT64:
      code = ArrowArrayAppendInt(out, ArrowArrayViewGetIntUnsafe(values, i));
      break;
    case NANOARROW_TYPE_DOUBLE:
      code =
        ArrowArrayAppendDouble(out, ArrowArrayViewGetDoubleUnsafe(values, i));
      break;
    case NANOARROW_TYPE_STRING:
    case NANOARROW_TYPE_BINARY:
      code =
        ArrowArrayAppendBytes(out, ArrowArrayViewGetBytesUnsafe(values, i));
      break;
    default:
      throw std::runtime_error(
        "Internal error: can't copy Arrow values of type " +
        std::string(ArrowTypeString(values->storage_type))
      );
    }
  }
  check_arrow(code, "Can't append to Arrow array");
}

void SqliteResultImpl::copy_pending_rows(struct ArrowArray* out, int64_t n) {
  nanoarrow::UniqueSchema schema;
  set_arrow_struct_schema(schema.get());

  struct ArrowError error;
  ArrowErrorInit(&error);
  nanoarrow::UniqueArrayView view;
  check_arrow(
    ArrowArrayViewInitFromSchema(view.get(), schema.get(), &error),
    "Can't read Arrow array",
    &error
  );
  check_arrow(
    ArrowArrayViewSetArray(view.get(), pending_chunk_.get(), &error),
    "Can't read Arrow array",
    &error
  );

  nanoarrow::UniqueArray chunk;
  check_arrow(
    ArrowArrayInitFromSchema(chunk.get(), schema.get(), &error),
    "Can't allocate Arrow array",
    &error
  );
  check_arrow(
    ArrowArrayStartAppending(chunk.get()),
    "Can't allocate Arrow array"
  );
  for (int64_t i = pending_offset_; i < pending_offset_ + n; ++i) {
    for (int64_t j = 0; j < chunk->n_children; ++j) {
      append_arrow_value(chunk->children[j], view->children[j], i);
    }
    check_arrow(
      ArrowArrayFinishElement(chunk.get()),
      "Can't append to Arrow array"
    );
  }
  check_arrow(
    ArrowArrayFinishBuildingDefault(chunk.get(), &error),
    "Can't finish Arrow array",
    &error
  );

  chunk.move(out);
}

bool SqliteResultImpl::arrow_row_fits() {
  for (size_t j = 0; j < arrow_columns_.size(); ++j) {
    SqliteArrowColumn& column = arrow_columns_[j];
    int64_t bytes = column.value_bytes();
    if (bytes > 0 && column.variable_bytes() + bytes > arrow_max_bytes) {
      return false;
    }
  }
  return true;
}

bool SqliteResultImpl::arrow_chunk_full() {
  for (size_t j = 0; j < arrow_columns_.size(); ++j) {
    if (arrow_columns_[j].variable_bytes() >= arrow_cut_bytes) {
      return true;
    }
  }
  return false;
}

std::pair<int64_t, int64_t> SqliteResultImpl::set_arrow_bytes_limits(
  int64_t cut_bytes,
  int64_t max_bytes
) {
  std::pair<int64_t, int64_t> old(arrow_cut_bytes, arrow_max_bytes);
  arrow_cut_bytes = cut_bytes;
  arrow_max_bytes = max_bytes;
  return old;
}

void SqliteResultImpl::raise_sqlite_exception(int rc) const {
  if (!connection_->is_valid()) {
    // After dbDisconnect(), sqlite3_close_v2() has left a handle whose
    // sqlite3_errmsg() only reports API misuse: an Arrow stream that reads on
    // has the result code
    throw std::runtime_error(
      std::string(sqlite3_errstr(rc)) +
      " (no details, the connection has been closed)"
    );
  }
  raise_sqlite_exception(conn);
}

// Throws a C++ exception rather than an R error, so that the fetch loop can
// also run inside an Arrow stream callback; cpp11 turns it into an R error
// at the entry point.
void SqliteResultImpl::raise_sqlite_exception(sqlite3* conn) {
  throw std::runtime_error(sqlite3_errmsg(conn));
}
