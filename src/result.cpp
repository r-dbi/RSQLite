#include <Rcpp.h>
#include "SqliteResult.h"
using namespace Rcpp;

// [[Rcpp::export]]
XPtr<SqliteResult> rsqlite_send_query(XPtr<SqliteConnectionPtr> con, std::string sql) {
  SqliteResult* res = new SqliteResult((*con), sql);
  return XPtr<SqliteResult>(res, true);
}

// [[Rcpp::export]]
void rsqlite_clear_result(XPtr<SqliteResult> res) {
  res.release();
}

// [[Rcpp::export]]
List rsqlite_fetch(XPtr<SqliteResult> res, int n = 10) {
  if (n < 0) {
    return res->fetch_all();  
  } else {
    return res->fetch(n);
  }
}

// [[Rcpp::export]]
void rsqlite_bind_params(XPtr<SqliteResult> res, List params) {
  res->bind(params);
}


// [[Rcpp::export]]
bool rsqlite_has_completed(XPtr<SqliteResult> res) {
  return res->complete();
}

// [[Rcpp::export]]
int rsqlite_row_count(XPtr<SqliteResult> res) {
  return res->nrows() - 1;
}

// [[Rcpp::export]]
int rsqlite_rows_affected(XPtr<SqliteResult> res) {
  return res->rows_affected();
}

// [[Rcpp::export]]
List rsqlite_column_info(XPtr<SqliteResult> res) {
  return res->column_info();
}

// [[Rcpp::export]]
bool rsqlite_result_valid(XPtr<SqliteResult> res) {
  return res;
}
