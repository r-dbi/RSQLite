#include "pch.h"
#include <workarounds/XPtr.h>
#include "DbResult.h"

// [[Rcpp::export]]
XPtr<DbResult> rsqlite_send_query(const XPtr<DbConnectionPtr>& con, const std::string& sql) {
  DbResult* res = new DbResult((*con), sql);
  return XPtr<DbResult>(res, true);
}

// [[Rcpp::export]]
void rsqlite_clear_result(XPtr<DbResult>& res) {
  res.release();
}

// [[Rcpp::export]]
List rsqlite_fetch(const XPtr<DbResult>& res, const int n = 10) {
  return res->fetch(n);
}

// [[Rcpp::export]]
CharacterVector rsqlite_get_placeholder_names(const XPtr<DbResult>& res) {
  return res->get_placeholder_names();
}

// [[Rcpp::export]]
void rsqlite_bind_rows(const XPtr<DbResult>& res, List params) {
  res->bind_rows(params);
}


// [[Rcpp::export]]
bool rsqlite_has_completed(const XPtr<DbResult>& res) {
  return res->complete();
}

// [[Rcpp::export]]
int rsqlite_row_count(const XPtr<DbResult>& res) {
  return res->nrows();
}

// [[Rcpp::export]]
int rsqlite_rows_affected(const XPtr<DbResult>& res) {
  return res->rows_affected();
}

// [[Rcpp::export]]
List rsqlite_column_info(const XPtr<DbResult>& res) {
  return res->get_column_info();
}

// [[Rcpp::export]]
bool rsqlite_result_valid(const XPtr<DbResult>& res) {
  return res.get() != NULL;
}
