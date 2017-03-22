#include <RSQLite.h>
#include "SqliteResultImpl.h"
#include "SqliteDataFrame.h"



// Construction ////////////////////////////////////////////////////////////////

SqliteResultImpl::SqliteResultImpl(sqlite3* conn_, const std::string& sql)
  : conn(conn_),
    stmt(prepare(conn_, sql)),
    cache(stmt),
    complete_(false),
    ready_(false),
    nrows_(0),
    rows_affected_(0),
    group_(0),
    groups_(0),
    types_(get_initial_field_types(cache.ncols_))
{
  LOG_VERBOSE << sql;

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

SqliteResultImpl::~SqliteResultImpl() {
  LOG_VERBOSE;

  try {
    sqlite3_finalize(stmt);
  } catch (...) {}
}

sqlite3_stmt* SqliteResultImpl::prepare(sqlite3* conn, const std::string& sql) {
  sqlite3_stmt* stmt = NULL;

  int rc = sqlite3_prepare_v2(conn, sql.c_str(), sql.size() + 1,
                              &stmt, NULL);
  if (rc != SQLITE_OK) {
    raise_sqlite_exception(conn);
  }

  return stmt;
}

// We guess the correct R type for each column from the declared column type,
// if possible.  The type of the column can be amended as new values come in,
// but will be fixed after the first call to fetch().
std::vector<SEXPTYPE> SqliteResultImpl::get_initial_field_types(const int ncols) {
  std::vector<SEXPTYPE> types;
  for (int j = 0; j < ncols; ++j) {
    types.push_back(NILSXP);
  }

  return types;
}

void SqliteResultImpl::after_bind(bool params_have_rows) {
  init(params_have_rows);
  if (params_have_rows)
    step();
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

int SqliteResultImpl::nrows() {
  return nrows_;
}

int SqliteResultImpl::rows_affected() {
  return rows_affected_;
}

IntegerVector SqliteResultImpl::find_params_impl(const CharacterVector& param_names) {
  int p = param_names.length();
  IntegerVector res(p);

  for (int j = 0; j < p; ++j) {
    int pos = find_parameter(CHAR(param_names[j]));
    if (pos == 0)
      pos = NA_INTEGER;
    res[j] = pos;
  }

  return res;
}

void SqliteResultImpl::bind_impl(const List& params) {
  bind_rows_impl(params);
}

void SqliteResultImpl::bind_rows_impl(const List& params) {
  if (params.size() != cache.nparams_) {
    stop("Query requires %i params; %i supplied.",
         cache.nparams_, params.size());
  }

  if (cache.nparams_ == 0)
    return;

  set_params(params);

  SEXP first_col = params[0];
  groups_ = Rf_length(first_col);
  group_ = 0;

  rows_affected_ = 0;

  bool has_params = bind_row();
  after_bind(has_params);
}

List SqliteResultImpl::fetch_impl(const int n_max) {
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

List SqliteResultImpl::get_column_info_impl() {
  peek_first_row();

  CharacterVector names(cache.names_.begin(), cache.names_.end());

  CharacterVector types(cache.ncols_);
  for (int i = 0; i < cache.ncols_; i++) {
    types[i] = Rf_type2char(types_[i]);
  }

  return List::create(names, types);
}



// Privates ////////////////////////////////////////////////////////////////////

void SqliteResultImpl::set_params(const List& params) {
  params_ = params;
  CharacterVector names = params.names();

  param_cache.names_.clear();
  if (names.length() == 0) {
    param_cache.names_.resize(params.length());
  }
  else {
    param_cache.names_ = as<std::vector<std::string> >(names);
  }
}

bool SqliteResultImpl::bind_row() {
  LOG_VERBOSE << "groups: " << group_ << "/" << groups_;

  if (group_ >= groups_)
    return false;

  sqlite3_reset(stmt);
  sqlite3_clear_bindings(stmt);

  for (size_t j = 0; j < param_cache.names_.size(); ++j) {
    bind_parameter(j, param_cache.names_[j], params_[j]);
  }

  return true;
}

void SqliteResultImpl::bind_parameter(int j0, const std::string& name, SEXP values_) {
  if (name != "") {
    int j = find_parameter(name);
    if (j == 0)
      stop("No parameter with name %s.", name);
    bind_parameter_pos(j, values_);
  } else {
    // sqlite parameters are 1-indexed
    bind_parameter_pos(j0 + 1, values_);
  }
}

int SqliteResultImpl::find_parameter(const std::string& name) {
  int i = 0;
  i = sqlite3_bind_parameter_index(stmt, name.c_str());
  if (i != 0)
    return i;

  std::string colon = ":" + name;
  i = sqlite3_bind_parameter_index(stmt, colon.c_str());
  if (i != 0)
    return i;

  std::string dollar = "$" + name;
  i = sqlite3_bind_parameter_index(stmt, dollar.c_str());
  if (i != 0)
    return i;

  return 0;
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
  } else if (TYPEOF(value_) == INTSXP) {
    int value = INTEGER(value_)[group_];
    if (value == NA_INTEGER) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_int(stmt, j, value);
    }
  } else if (TYPEOF(value_) == REALSXP) {
    double value = REAL(value_)[group_];
    if (value == NA_REAL) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_double(stmt, j, value);
    }
  } else if (TYPEOF(value_) == STRSXP) {
    SEXP value = STRING_ELT(value_, group_);
    if (value == NA_STRING) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_text(stmt, j, CHAR(value), -1, SQLITE_TRANSIENT);
    }
  } else if (TYPEOF(value_) == VECSXP) {
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
  } else {
    stop("Don't know how to handle parameter of type %s.",
         Rf_type2char(TYPEOF(value_)));
  }
}

List SqliteResultImpl::fetch_rows(const int n_max, int& n) {
  n = (n_max < 0) ? 100 : n_max;

  SqliteDataFrame data(stmt, cache.names_, n_max, types_);

  while (!complete_) {
    LOG_VERBOSE << nrows_ << "/" << n;

    if (!data.set_col_values())
      break;

    step();
    data.advance();
    nrows_++;
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
  rows_affected_ += sqlite3_changes(conn);

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
