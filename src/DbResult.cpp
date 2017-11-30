#include "pch.h"
#include "DbResult.h"
#include "SqliteResultImpl.h"



// Construction ////////////////////////////////////////////////////////////////

SqliteResult::SqliteResult(const SqliteConnectionPtr& pConn, const std::string& sql)
  : pConn_(pConn), impl(new SqliteResultImpl(pConn->conn(), sql)) {}

SqliteResult::~SqliteResult() {}


// Publics /////////////////////////////////////////////////////////////////////

bool SqliteResult::complete() {
  return impl->complete();
}

int SqliteResult::nrows() {
  return impl->nrows();
}

int SqliteResult::rows_affected() {
  return impl->rows_affected();
}

CharacterVector SqliteResult::get_placeholder_names() const {
  return impl->get_placeholder_names();
}

void SqliteResult::bind_rows(const List& params) {
  validate_params(params);
  impl->bind_rows_impl(params);
}

List SqliteResult::fetch(const int n_max) {
  return impl->fetch_impl(n_max);

}

List SqliteResult::get_column_info() {
  List out = impl->get_column_info_impl();

  out.attr("row.names") = IntegerVector::create(NA_INTEGER, -Rf_length(out[0]));
  out.attr("class") = "data.frame";
  out.names() = CharacterVector::create("name", "type");

  return out;
}


// Privates ///////////////////////////////////////////////////////////////////

void SqliteResult::validate_params(const List& params) const {
  if (params.size() != 0) {
    SEXP first_col = params[0];
    int n = Rf_length(first_col);

    for (int j = 1; j < params.size(); ++j) {
      SEXP col = params[j];
      if (Rf_length(col) != n)
        stop("Parameter %i does not have length %d.", j + 1, n);
    }
  }
}
