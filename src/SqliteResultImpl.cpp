#include <cpp11.hpp>
#include "pch.h"
#include "SqliteResultImpl.h"
#include "SqliteDataFrame.h"
#include "DbColumnStorage.h"
#include "DbConnection.h"
#include "integer64.h"
#include <sstream>

// Variable-width columns end a chunk once one of them holds this many bytes
static const int64_t ARROW_MAX_VAR_BYTES = int64_t(1) << 30;

// Construction ////////////////////////////////////////////////////////////////

SqliteResultImpl::SqliteResultImpl(
  const DbConnectionPtr& conn_,
  const std::string& sql
)
    : conn(conn_->conn()),
      stmt(prepare(conn, sql)),
      cache(stmt),
      complete_(false),
      ready_(false),
      nrows_(0),
      total_changes_start_(sqlite3_total_changes(conn)),
      types_(get_initial_field_types(cache.ncols_)),
      with_alt_types_(conn_->with_alt_types()),
      arrow_frozen_(false) {
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

bool SqliteResultImpl::complete() const {
  return complete_;
}

bool SqliteResultImpl::ready() const {
  return ready_;
}

int SqliteResultImpl::n_rows_fetched() {
  return nrows_;
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
      nanoarrow::UniqueArray chunk;
      fetch_arrow_rows(chunk.get(), infer_rows);
      chunk.move(pending_chunk_.get());
    }
    // Columns that only ever held NULL take their declared type
    for (size_t j = 0; j < arrow_columns_.size(); ++j) {
      arrow_columns_[j].decide_from_decltype();
    }
    freeze_arrow_columns();
  }

  ArrowSchemaInit(out);
  check_arrow(
    ArrowSchemaSetTypeStruct(out, static_cast<int64_t>(arrow_columns_.size())),
    "Can't allocate Arrow schema"
  );
  for (size_t j = 0; j < arrow_columns_.size(); ++j) {
    arrow_columns_[j].set_schema(out->children[j]);
  }
}

int64_t SqliteResultImpl::fetch_arrow(struct ArrowArray* out, int64_t n_max) {
  if (!ready_) {
    throw std::runtime_error("Query needs to be bound before fetching");
  }

  ensure_arrow_columns();

  if (pending_chunk_->release != NULL) {
    int64_t n = pending_chunk_->length;
    pending_chunk_.move(out);
    return n;
  }

  return fetch_arrow_rows(out, n_max);
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
  after_set_params();
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
  // A new execution may see other values in the first row
  arrow_columns_.clear();
  arrow_frozen_ = false;
  pending_chunk_.reset();

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
    raise_sqlite_exception();
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

int64_t SqliteResultImpl::fetch_arrow_rows(
  struct ArrowArray* out,
  int64_t n_max
) {
  const size_t ncols = arrow_columns_.size();

  for (size_t j = 0; j < ncols; ++j) {
    arrow_columns_[j].start_chunk();
  }

  int64_t n = 0;
  while (!complete_ && n < n_max) {
    for (size_t j = 0; j < ncols; ++j) {
      arrow_columns_[j].append_row();
    }
    step();
    ++nrows_;
    ++n;

    if (n % 1024 == 0) {
      cpp11::check_user_interrupt();

      bool full = false;
      for (size_t j = 0; j < ncols; ++j) {
        if (arrow_columns_[j].variable_bytes() >= ARROW_MAX_VAR_BYTES) {
          full = true;
          break;
        }
      }
      if (full) {
        break;
      }
    }
  }

  for (size_t j = 0; j < ncols; ++j) {
    arrow_columns_[j].finish_chunk(n);
  }
  // The types are final from the first chunk on
  freeze_arrow_columns();

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
    arrow_columns_[j].move_chunk_to(chunk->children[j]);
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

void SqliteResultImpl::raise_sqlite_exception() const {
  raise_sqlite_exception(conn);
}

// Throws a C++ exception rather than an R error, so that the fetch loop can
// also run inside an Arrow stream callback; cpp11 turns it into an R error
// at the entry point.
void SqliteResultImpl::raise_sqlite_exception(sqlite3* conn) {
  throw std::runtime_error(sqlite3_errmsg(conn));
}
