#include "pch.h"
#include <workarounds/XPtr.h>
#include "DbResult.h"

// [[Rcpp::export]]
XPtr<DbResult> result_send_query(const XPtr<DbConnectionPtr>& con, const std::string& sql) {
  DbResult* res = new DbResult((*con), sql);
  return XPtr<DbResult>(res, true);
}

// [[Rcpp::export]]
void result_clear_result(XPtr<DbResult>& res) {
  res.release();
}

// [[Rcpp::export]]
List result_fetch(DbResult* res, const int n) {
  return res->fetch(n);
}

// [[Rcpp::export]]
CharacterVector result_get_placeholder_names(const XPtr<DbResult>& res) {
  return res->get_placeholder_names();
}

// [[Rcpp::export]]
void result_bind_rows(const XPtr<DbResult>& res, List params) {
  res->bind_rows(params);
}


// [[Rcpp::export]]
bool result_has_completed(const XPtr<DbResult>& res) {
  return res->complete();
}

// [[Rcpp::export]]
int result_row_count(const XPtr<DbResult>& res) {
  return res->nrows();
}

// [[Rcpp::export]]
int result_rows_affected(const XPtr<DbResult>& res) {
  return res->rows_affected();
}

// [[Rcpp::export]]
List result_column_info(const XPtr<DbResult>& res) {
  return res->get_column_info();
}

// [[Rcpp::export]]
bool result_result_valid(const XPtr<DbResult>& res) {
  return res.get() != NULL;
}

namespace Rcpp {

template<>
DbResult* as(SEXP x) {
  DbResult* result = (DbResult*)(R_ExternalPtrAddr(x));
  if (!result)
    stop("Invalid result set");
  return result;
}

}
