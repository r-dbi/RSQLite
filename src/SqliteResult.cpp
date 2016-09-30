#include <RSQLite.h>
#include "SqliteResult.h"

#include "SqliteResultImpl.h"



// Construction ////////////////////////////////////////////////////////////////

SqliteResult::SqliteResult(const SqliteConnectionPtr& pConn, const std::string& sql)
  : pConn_(pConn), SqliteResultImpl::pStatement_(NULL), SqliteResultImpl::complete_(false), SqliteResultImpl::ready_(false),
    SqliteResultImpl::nrows_(0), SqliteResultImpl::ncols_(0), SqliteResultImpl::rows_affected_(0), SqliteResultImpl::nparams_(0) {

  SqliteResultImpl::prepare(sql);

  try {
    SqliteResultImpl::init_if_bound();
  } catch (...) {
    sqlite3_finalize(SqliteResultImpl::pStatement_);
    SqliteResultImpl::pStatement_ = NULL;
    throw;
  }
}


// Initialization //////////////////////////////////////////////////////////////


// Publics /////////////////////////////////////////////////////////////////////

bool SqliteResult::complete() {
  return SqliteResultImpl::complete_;
}

int SqliteResult::nrows() {
  return SqliteResultImpl::nrows_;
}

int SqliteResult::rows_affected() {
  return SqliteResultImpl::rows_affected_;
}

IntegerVector SqliteResult::find_params(const CharacterVector& param_names) {
  return SqliteResultImpl::find_params_impl(param_names);
}

void SqliteResult::bind(const List& params) {
  if (params.size() != SqliteResultImpl::nparams_) {
    stop("Query requires %i params; %i supplied.",
         SqliteResultImpl::nparams_, params.size());
  }
  if (params.attr("names") == R_NilValue) {
    stop("Parameters must be a named list.");
  }

  for (int j = 0; j < params.size(); ++j) {
    SEXP col = params[j];
    if (Rf_length(col) != 1)
      stop("Parameter %i does not have length 1.", j + 1);
  }

  SqliteResultImpl::bind_impl(params);
  SqliteResultImpl::init();
}

void SqliteResult::bind_rows(const List& params) {
  if (params.size() != SqliteResultImpl::nparams_) {
    stop("Query requires %i params; %i supplied.",
         SqliteResultImpl::nparams_, params.size());
  }
  if (params.size() == 0) {
    stop("Need at least one column");
  }

  SqliteResultImpl::bind_rows_impl(params);
}

List SqliteResult::fetch(const int n_max) {
  return SqliteResultImpl::fetch_impl(n_max);

}

List SqliteResult::get_column_info() {
  List out = SqliteResultImpl::get_column_info_impl();

  out.attr("row.names") = IntegerVector::create(NA_INTEGER, -SqliteResultImpl::ncols_);
  out.attr("class") = "data.frame";
  out.attr("names") = CharacterVector::create("name", "type");

  return out;
}


// Privates ////////////////////////////////////////////////////////////////////

