#include "pch.h"
#include "SqliteResultImpl.h"
#include "SqliteDataFrame.h"
#include "DbColumnStorage.h"
#include "integer64.h"



// Construction ////////////////////////////////////////////////////////////////

SqliteResultImpl::SqliteResultImpl(sqlite3* conn_, const std::string& sql) :
  conn(conn_),
  stmt(prepare(conn_, sql)),
  cache(stmt),
  complete_(false),
  ready_(false),
  nrows_(0),
  total_changes_start_(sqlite3_total_changes(conn_)),
  group_(0),
  groups_(0),
  types_(get_initial_field_types(cache.ncols_))
{

  LOG_DEBUG << sql;

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
  LOG_VERBOSE;

  try {
    sqlite3_finalize(stmt);
  } catch (...) {}
}



// Cache ///////////////////////////////////////////////////////////////////////

SqliteResultImpl::_cache::_cache(sqlite3_stmt* stmt)
  : names_(get_column_names(stmt)),
    ncols_(names_.size()),
    nparams_(sqlite3_bind_parameter_count(stmt))
{
}

std::vector<std::string> SqliteResultImpl::_cache::get_column_names(sqlite3_stmt* stmt) {
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
std::vector<DATA_TYPE> SqliteResultImpl::get_initial_field_types(const size_t ncols) {
  std::vector<DATA_TYPE> types(ncols);
  std::fill(types.begin(), types.end(), DT_UNKNOWN);
  return types;
}

sqlite3_stmt* SqliteResultImpl::prepare(sqlite3* conn, const std::string& sql) {
  sqlite3_stmt* stmt = NULL;

  int rc =
    sqlite3_prepare_v2(
      conn, sql.c_str(), (int)std::min(sql.size() + 1, (size_t)INT_MAX),
      &stmt, NULL
    );
  if (rc != SQLITE_OK) {
    raise_sqlite_exception(conn);
  }

  return stmt;
}

void SqliteResultImpl::init(bool params_have_rows) {
  ready_ = true;
  nrows_ = 0;
  complete_ = !params_have_rows;
}



// Publics /////////////////////////////////////////////////////////////////////

bool SqliteResultImpl::complete() {
  return complete_;
}

int SqliteResultImpl::n_rows_fetched() {
  return nrows_;
}

int SqliteResultImpl::n_rows_affected() {
  if (!ready_) return NA_INTEGER;
  return sqlite3_total_changes(conn) - total_changes_start_;
}

void SqliteResultImpl::bind(const List& params) {
  if (cache.nparams_ == 0) {
    stop("Query does not require parameters.");
  }

  if (params.size() != cache.nparams_) {
    stop("Query requires %i params; %i supplied.",
         cache.nparams_, params.size());
  }

  set_params(params);

  SEXP first_col = params[0];
  groups_ = Rf_length(first_col);
  group_ = 0;

  total_changes_start_ = sqlite3_total_changes(conn);

  bool has_params = bind_row();
  after_bind(has_params);
}

List SqliteResultImpl::fetch(const int n_max) {
  if (!ready_)
    stop("Query needs to be bound before fetching");

  int n = 0;
  List out;

  if (n_max != 0)
    out = fetch_rows(n_max, n);
  else
    out = peek_first_row();

  return out;
}

List SqliteResultImpl::get_column_info() {
  peek_first_row();

  CharacterVector names(cache.names_.begin(), cache.names_.end());

  CharacterVector types(cache.ncols_);
  for (size_t i = 0; i < cache.ncols_; i++) {
    types[i] = Rf_type2char(DbColumnStorage::sexptype_from_datatype(types_[i]));
  }

  return List::create(names, types);
}



// Publics (custom) ////////////////////////////////////////////////////////////

CharacterVector SqliteResultImpl::get_placeholder_names() const {
  int n = sqlite3_bind_parameter_count(stmt);

  CharacterVector res(n);

  for (int i = 0; i < n; ++i) {
    const char* placeholder_name = sqlite3_bind_parameter_name(stmt, i + 1);
    if (placeholder_name == NULL)
      placeholder_name = "";
    else
      ++placeholder_name;
    res[i] = String(placeholder_name, CE_UTF8);
  }

  return res;
}



// Privates ////////////////////////////////////////////////////////////////////

void SqliteResultImpl::set_params(const List& params) {
  params_ = params;
}

bool SqliteResultImpl::bind_row() {
  LOG_VERBOSE << "groups: " << group_ << "/" << groups_;

  if (group_ >= groups_)
    return false;

  sqlite3_reset(stmt);
  sqlite3_clear_bindings(stmt);

  for (R_xlen_t j = 0; j < params_.size(); ++j) {
    // sqlite parameters are 1-indexed
    bind_parameter_pos((int)j + 1, params_[j]);
  }

  return true;
}

void SqliteResultImpl::bind_parameter_pos(int j, SEXP value_) {
  LOG_VERBOSE << "TYPEOF(value_): " << TYPEOF(value_);

  if (TYPEOF(value_) == LGLSXP) {
    int value = LOGICAL(value_)[group_];
    if (value == NA_LOGICAL) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_int(stmt, j, value);
    }
  }
  else if (TYPEOF(value_) == INT64SXP && Rf_inherits(value_, "integer64")) {
    int64_t value = INTEGER64(value_)[group_];
    if (value == NA_INTEGER64) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_int64(stmt, j, value);
    }
  }
  else if (TYPEOF(value_) == INTSXP) {
    int value = INTEGER(value_)[group_];
    if (value == NA_INTEGER) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_int(stmt, j, value);
    }
  }
  else if (TYPEOF(value_) == REALSXP) {
    double value = REAL(value_)[group_];
    if (value == NA_REAL) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_double(stmt, j, value);
    }
  }
  else if (TYPEOF(value_) == STRSXP) {
    SEXP value = STRING_ELT(value_, group_);
    if (value == NA_STRING) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_text(stmt, j, CHAR(value), -1, SQLITE_TRANSIENT);
    }
  }
  else if (TYPEOF(value_) == VECSXP) {
    SEXP value = VECTOR_ELT(value_, group_);
    if (TYPEOF(value) == NILSXP) {
      sqlite3_bind_null(stmt, j);
    }
    else if (TYPEOF(value) == RAWSXP) {
      sqlite3_bind_blob(stmt, j, RAW(value), Rf_length(value), SQLITE_TRANSIENT);
    }
    else {
      stop("Can only bind lists of raw vectors (or NULL)");
    }
  }
  else {
    stop("Don't know how to handle parameter of type %s.",
         Rf_type2char(TYPEOF(value_)));
  }
}

void SqliteResultImpl::after_bind(bool params_have_rows) {
  init(params_have_rows);
  if (params_have_rows)
    step();
}

List SqliteResultImpl::fetch_rows(const int n_max, int& n) {
  n = (n_max < 0) ? 100 : n_max;

  SqliteDataFrame data(stmt, cache.names_, n_max, types_);

  if (complete_ && data.get_ncols() == 0) {
    warning("Don't need to call dbFetch() for statements, only for queries");
  }

  while (!complete_) {
    LOG_VERBOSE << nrows_ << "/" << n;

    data.set_col_values();
    step();
    nrows_++;
    if (!data.advance())
      break;
  }

  LOG_VERBOSE << nrows_;

  return data.get_data(types_);
}

void SqliteResultImpl::step() {
  while (step_run())
    ;
}

bool SqliteResultImpl::step_run() {
  LOG_VERBOSE;

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
  ++group_;
  bool more_params = bind_row();

  if (!more_params)
    complete_ = true;

  LOG_VERBOSE << "group: " << group_ << ", more_params: " << more_params;
  return more_params;
}

List SqliteResultImpl::peek_first_row() {
  SqliteDataFrame data(stmt, cache.names_, 1, types_);

  if (!complete_)
    data.set_col_values();
  // Not calling data.advance(), remains a zero-row data frame

  return data.get_data(types_);
}

void SqliteResultImpl::raise_sqlite_exception() const {
  raise_sqlite_exception(conn);
}

void SqliteResultImpl::raise_sqlite_exception(sqlite3* conn) {
  stop(sqlite3_errmsg(conn));
}
