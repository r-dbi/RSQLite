#include <cpp11.hpp>
#include "pch.h"
#include "SqliteResultImpl.h"
#include "SqliteDataFrame.h"
#include "DbColumnStorage.h"
#include "DbConnection.h"
#include "integer64.h"
#include <stdexcept>

namespace {

// An error of a step, from SQLite or from a parameter that cannot be bound,
// with SQLite's result code:
// the code of SQLite's refusal for a value it does not accept,
// such as SQLITE_TOOBIG,
// and SQLITE_ERROR for a parameter of a type that cannot be bound.
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

}  // namespace

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
      total_changes_start_(sqlite3_total_changes64(conn)),
      group_(0),
      groups_(0),
      types_(get_initial_field_types(cache.ncols_)),
      with_alt_types_(conn_->with_alt_types()),
      check_utf8_(conn_->check_utf8()),
      error_kept_(false),
      kept_error_completes_(false),
      kept_error_code_(SQLITE_OK) {
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
      cpp11::warning("Ignoring remaining part of query: %s", tail);
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

int64_t SqliteResultImpl::n_rows_fetched() {
  return nrows_;
}

// Before a bind, NA_INTEGER, which result_rows_affected() returns as NA
int64_t SqliteResultImpl::n_rows_affected() {
  if (!ready_) {
    return NA_INTEGER;
  }
  return sqlite3_total_changes64(conn) - total_changes_start_;
}

void SqliteResultImpl::set_rows_fetched(int64_t n) {
  nrows_ = n;
}

void SqliteResultImpl::set_rows_affected(int64_t n) {
  total_changes_start_ = sqlite3_total_changes64(conn) - n;
}

void SqliteResultImpl::bind(const cpp11::list& params) {
  if (cache.nparams_ == 0) {
    cpp11::stop("Query does not require parameters.");
  }

  if (params.size() != cache.nparams_) {
    cpp11::stop(
      "Query requires %i params; %i supplied.",
      cache.nparams_,
      static_cast<int>(params.size())
    );
  }

  set_params(params);

  SEXP first_col = cpp11::as_sexp(params[0]);
  groups_ = Rf_length(first_col);
  group_ = 0;

  total_changes_start_ = sqlite3_total_changes64(conn);

  // Until the first row is bound, the result counts as unbound,
  // so that a failed bind doesn't leave the previous binding's state behind.
  ready_ = false;
  complete_ = true;
  nrows_ = 0;

  // A new execution starts: the error kept from the previous one is dropped
  error_kept_ = false;
  kept_error_completes_ = false;
  kept_error_.clear();
  kept_error_code_ = SQLITE_OK;

  bool has_params = bind_row();
  after_bind(has_params);
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

void SqliteResultImpl::set_params(const cpp11::list& params) {
  params_ = params;
}

bool SqliteResultImpl::bind_row() {
  if (group_ >= groups_) {
    return false;
  }

  sqlite3_reset(stmt);
  sqlite3_clear_bindings(stmt);

  for (R_xlen_t j = 0; j < params_.size(); ++j) {
    // sqlite parameters are 1-indexed
    bind_parameter_pos((int)j + 1, params_[j]);
  }

  return true;
}

void SqliteResultImpl::bind_parameter_pos(int j, SEXP value_) {
  int rc = SQLITE_OK;
  if (TYPEOF(value_) == LGLSXP) {
    int value = LOGICAL(value_)[group_];
    if (value == NA_LOGICAL) {
      rc = sqlite3_bind_null(stmt, j);
    } else {
      rc = sqlite3_bind_int(stmt, j, value);
    }
  } else if (TYPEOF(value_) == INT64SXP && Rf_inherits(value_, "integer64")) {
    int64_t value = INTEGER64(value_)[group_];
    if (value == NA_INTEGER64) {
      rc = sqlite3_bind_null(stmt, j);
    } else {
      rc = sqlite3_bind_int64(stmt, j, value);
    }
  } else if (TYPEOF(value_) == INTSXP) {
    int value = INTEGER(value_)[group_];
    if (value == NA_INTEGER) {
      rc = sqlite3_bind_null(stmt, j);
    } else {
      rc = sqlite3_bind_int(stmt, j, value);
    }
  } else if (TYPEOF(value_) == REALSXP) {
    double value = REAL(value_)[group_];
    if (value == NA_REAL) {
      rc = sqlite3_bind_null(stmt, j);
    } else {
      rc = sqlite3_bind_double(stmt, j, value);
    }
  } else if (TYPEOF(value_) == STRSXP) {
    SEXP value = STRING_ELT(value_, group_);
    if (value == NA_STRING) {
      rc = sqlite3_bind_null(stmt, j);
    } else {
      rc = sqlite3_bind_text(stmt, j, CHAR(value), -1, SQLITE_TRANSIENT);
    }
  } else if (TYPEOF(value_) == VECSXP) {
    SEXP value = VECTOR_ELT(value_, group_);
    if (TYPEOF(value) == NILSXP) {
      rc = sqlite3_bind_null(stmt, j);
    } else if (TYPEOF(value) == RAWSXP) {
      rc = sqlite3_bind_blob(
        stmt,
        j,
        RAW(value),
        Rf_length(value),
        SQLITE_TRANSIENT
      );
    } else {
      throw step_error(
        "Can only bind lists of raw vectors (or NULL)",
        SQLITE_ERROR
      );
    }
  } else {
    throw step_error(
      std::string("Don't know how to handle parameter of type ") +
        Rf_type2char(TYPEOF(value_)) + ".",
      SQLITE_ERROR
    );
  }

  if (rc != SQLITE_OK) {
    raise_bind_exception(j, rc);
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

  // The step past the rows of the previous fetch failed
  if (error_kept_) {
    raise_kept_error();
  }

  SqliteDataFrame
    data(stmt, cache.names_, n_max, types_, with_alt_types_, check_utf8_);

  if (complete_ && data.get_ncols() == 0) {
    Rf_warning(
      "`dbGetQuery()`, `dbSendQuery()` and `dbFetch()` should only be used "
      "with `SELECT` queries. Did you mean `dbExecute()`, `dbSendStatement()` "
      "or `dbGetRowsAffected()`?"
    );
  }

  int n_read = 0;
  while (!complete_) {
    data.set_col_values();
    // The step past the last row of a full fetch only reads ahead
    if (++n_read == n_max) {
      read_ahead();
    } else {
      step();
    }
    nrows_++;
    if (!data.advance()) {
      break;
    }
  }

  return data.get_data(types_);
}

// A failed step throws a step_error, which reaches R at the entry point
void SqliteResultImpl::step() {
  while (step_run())
    ;
}

// Steps past the last row of a full fetch.
// This step only tells whether the result is complete,
// and finishes the statement if it is, so that it releases its locks.
// An error is kept for the next fetch instead of costing the rows of this one;
// SQLite's message and result code are saved now,
// before later calls overwrite them.
void SqliteResultImpl::read_ahead() {
  try {
    while (step_run())
      ;
  } catch (const step_error& e) {
    error_kept_ = true;
    kept_error_ = e.what();
    kept_error_code_ = e.code();
    // A value SQLite refused to bind completes the result,
    // but only once the next fetch has raised the error:
    // until then, dbHasCompleted() stays FALSE.
    kept_error_completes_ = complete_;
    complete_ = false;
  }
}

bool SqliteResultImpl::step_run() {
  int rc = sqlite3_step(stmt);

  switch (rc) {
  case SQLITE_DONE:
    return step_done();
  case SQLITE_ROW:
    return false;
  default:
    throw step_error(sqlite3_errmsg(conn), rc);
  }
}

bool SqliteResultImpl::step_done() {
  ++group_;
  bool more_params = bind_row();

  if (!more_params) {
    complete_ = true;
  }

  return more_params;
}

cpp11::list SqliteResultImpl::peek_first_row() {
  SqliteDataFrame
    data(stmt, cache.names_, 1, types_, with_alt_types_, check_utf8_);

  // After a failed step, the statement is on no row:
  // the kept error is left for the next fetch that reads rows
  if (!complete_ && !error_kept_) {
    data.set_col_values();
  }
  // Not calling data.advance(), remains a zero-row data frame

  return data.get_data(types_);
}

void SqliteResultImpl::raise_kept_error() {
  step_error error(kept_error_, kept_error_code_);
  if (kept_error_completes_) {
    complete_ = true;
  }
  error_kept_ = false;
  kept_error_completes_ = false;
  kept_error_.clear();
  kept_error_code_ = SQLITE_OK;
  throw error;
}

// Throws a C++ exception rather than an R error: cpp11 turns it into an R error
// at the entry point, with the message as it is, not as a format string.
void SqliteResultImpl::raise_sqlite_exception(sqlite3* conn) {
  throw std::runtime_error(sqlite3_errmsg(conn));
}

// A value SQLite refuses to bind, such as one over its length limit,
// would otherwise be bound as NULL.
// The result is marked complete, so that no fetch reads the reset statement;
// the next dbBind() resets the statement and binds afresh.
// It throws a step_error with SQLite's result code,
// so that read_ahead() can keep it like the error of a step.
void SqliteResultImpl::raise_bind_exception(int j, int rc) {
  complete_ = true;
  std::string message = "Can't bind parameter " + std::to_string(j);
  const char* name = sqlite3_bind_parameter_name(stmt, j);
  if (name != NULL) {
    message += std::string(" (") + name + ")";
  }
  message +=
    " in row " + std::to_string(group_ + 1) + ": " + sqlite3_errmsg(conn) + ".";
  throw step_error(message, rc);
}
