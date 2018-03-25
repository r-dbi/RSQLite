#include "pch.h"
#include "DbResult.h"
#include "SqliteResultImpl.h"



// Construction ////////////////////////////////////////////////////////////////

DbResult::DbResult(const DbConnectionPtr& pConn, const std::string& sql)
  : pConn_(pConn), impl(new SqliteResultImpl(pConn->conn(), sql)) {}

DbResult::~DbResult() {}

DbResult* DbResult::create_and_send_query(const DbConnectionPtr& con, const std::string& sql, bool is_statement) {
  (void)is_statement;
  return new DbResult(con, sql);
}


// Publics /////////////////////////////////////////////////////////////////////

bool DbResult::complete() {
  return impl->complete();
}

bool DbResult::is_active() const {
  return true;
}

int DbResult::n_rows_fetched() {
  return impl->n_rows_fetched();
}

int DbResult::n_rows_affected() {
  return impl->n_rows_affected();
}

CharacterVector DbResult::get_placeholder_names() const {
  return impl->get_placeholder_names();
}

void DbResult::bind(const List& params) {
  validate_params(params);
  impl->bind(params);
}

List DbResult::fetch(const int n_max) {
  return impl->fetch(n_max);

}

List DbResult::get_column_info() {
  List out = impl->get_column_info();

  out.attr("row.names") = IntegerVector::create(NA_INTEGER, -Rf_length(out[0]));
  out.attr("class") = "data.frame";
  out.names() = CharacterVector::create("name", "type");

  return out;
}


// Privates ///////////////////////////////////////////////////////////////////

void DbResult::validate_params(const List& params) const {
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
