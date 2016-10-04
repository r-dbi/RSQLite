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
    types_(get_initial_field_types(cache.ncols_))
{
  LOG_VERBOSE << sql;

  try {
    if (cache.nparams_ == 0) {
      after_bind();
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

void SqliteResultImpl::after_bind() {
  init();
  step();
}

void SqliteResultImpl::init() {
  ready_ = true;
  nrows_ = 0;
  complete_ = false;
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

  SEXP first_col = params[0];
  int n = Rf_length(first_col);

  rows_affected_ = 0;

  for (int i = 0; i < n; ++i) {
    bind_row(i, params);
    after_bind();
  }
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

void SqliteResultImpl::bind_row(int group, const List& params) {
  CharacterVector names = params.attr("names");
  sqlite3_reset(stmt);
  sqlite3_clear_bindings(stmt);

  for (int j = 0; j < params.size(); ++j) {
    bind_parameter(group, j, CHAR(names[j]), static_cast<SEXPREC*>(params[j]));
  }
}

void SqliteResultImpl::bind_parameter(const int group, const int j0, const std::string& name, const SEXP values_) {
  if (name != "") {
    int j = find_parameter(name);
    if (j == 0)
      stop("No parameter with name %s.", name);
    bind_parameter_pos(group, j, values_);
  } else {
    // sqlite parameters are 1-indexed
    bind_parameter_pos(group, j0 + 1, values_);
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

void SqliteResultImpl::bind_parameter_pos(const int i, const int j, const SEXP value_) {
  LOG_VERBOSE << "TYPEOF(value_): " << TYPEOF(value_) << "\n";
  if (TYPEOF(value_) == LGLSXP) {
    LogicalVector value(value_);
    if (value[i] == NA_LOGICAL) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_int(stmt, j, static_cast<int>(value[i]));
    }
  } else if (TYPEOF(value_) == INTSXP) {
    IntegerVector value(value_);
    if (value[i] == NA_INTEGER) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_int(stmt, j, static_cast<int>(value[i]));
    }
  } else if (TYPEOF(value_) == REALSXP) {
    NumericVector value(value_);
    if (value[i] == NA_REAL) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_double(stmt, j, static_cast<double>(value[i]));
    }
  } else if (TYPEOF(value_) == STRSXP) {
    CharacterVector value(value_);
    if (value[i] == NA_STRING) {
      sqlite3_bind_null(stmt, j);
    } else {
      String value2 = value[i];
      std::string value3(value2);
      sqlite3_bind_text(stmt, j, value3.data(), value3.size(),
                        SQLITE_TRANSIENT);
    }
  } else if (TYPEOF(value_) == VECSXP) {
    SEXP raw = VECTOR_ELT(value_, i);
    if (TYPEOF(raw) != RAWSXP) {
      stop("Can only bind lists of raw vectors");
    }

    sqlite3_bind_blob(stmt, j, RAW(raw), Rf_length(raw), SQLITE_TRANSIENT);
  } else {
    stop("Don't know how to handle parameter of type %s.",
         Rf_type2char(TYPEOF(value_)));
  }
}

List SqliteResultImpl::fetch_rows(const int n_max, int& n) {
  n = (n_max < 0) ? 100 : n_max;

  SqliteDataFrame data(stmt, cache.names_, n_max, types_);

  while (!complete_) {
    if (!data.set_col_values())
      break;

    step();
    data.advance();
  }

  return data.get_data(types_);
}

void SqliteResultImpl::step() {
  nrows_++;
  int rc = sqlite3_step(stmt);

  if (rc == SQLITE_DONE) {
    complete_ = true;
  } else if (rc != SQLITE_ROW) {
    raise_sqlite_exception();
  }

  rows_affected_ += sqlite3_changes(conn);
}

List SqliteResultImpl::peek_first_row() {
  SqliteDataFrame data(stmt, cache.names_, 1, types_);

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
