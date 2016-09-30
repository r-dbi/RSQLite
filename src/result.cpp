#include <RSQLite.h>
#include <workarounds/XPtr.h>
#include "SqliteResult.h"

// [[Rcpp::export]]
XPtr<SqliteResult> rsqlite_send_query(const XPtr<SqliteConnectionPtr>& con, const std::string& sql) {
  SqliteResult* res = new SqliteResult((*con), sql);
  return XPtr<SqliteResult>(res, true);
}

// [[Rcpp::export]]
void rsqlite_clear_result(XPtr<SqliteResult>& res) {
  res.release();
}

// [[Rcpp::export]]
List rsqlite_fetch(const XPtr<SqliteResult>& res, const int n = 10) {
  return res->fetch(n);
}

// [[Rcpp::export]]
void rsqlite_bind_params(const XPtr<SqliteResult>& res, List params) {
  res->bind(params);
}

// [[Rcpp::export]]
IntegerVector rsqlite_find_params(const XPtr<SqliteResult>& res, CharacterVector param_names) {
  return res->find_params(param_names);
}

// [[Rcpp::export]]
void rsqlite_bind_rows(const XPtr<SqliteResult>& res, List params) {
  res->bind_rows(params);
}


// [[Rcpp::export]]
bool rsqlite_has_completed(const XPtr<SqliteResult>& res) {
  return res->complete();
}

// [[Rcpp::export]]
int rsqlite_row_count(const XPtr<SqliteResult>& res) {
  return res->nrows() - 1;
}

// [[Rcpp::export]]
int rsqlite_rows_affected(const XPtr<SqliteResult>& res) {
  return res->rows_affected();
}

// [[Rcpp::export]]
List rsqlite_column_info(const XPtr<SqliteResult>& res) {
  return res->get_column_info();
}

// [[Rcpp::export]]
bool rsqlite_result_valid(const XPtr<SqliteResult>& res) {
  return res.get() != NULL;
}
