#include <Rcpp.h>
#include <RSQLite.h>
using namespace Rcpp;

// [[Rcpp::export]]
XPtr<SqliteResult> rsqlite_send_query(XPtr<SqliteConnection> con, std::string sql) {
  SqliteConnection* conn = (SqliteConnection*) R_ExternalPtrAddr(con);
  SqliteResult* res = new SqliteResult(conn, sql);
  return XPtr<SqliteResult>(res, true);
}

// [[Rcpp::export]]
void rsqlite_clear_result(XPtr<SqliteResult> res) {
  if (R_ExternalPtrAddr(res) == NULL) stop("Results already closed");
  
  SqliteResult* ress = (SqliteResult*) R_ExternalPtrAddr(res);
  delete ress;
  R_ClearExternalPtr(res);
}

// [[Rcpp::export]]
List rsqlite_fetch(XPtr<SqliteResult> res, int n = 10) {
  if (R_ExternalPtrAddr(res) == NULL) stop("Results closed");
  
  if (n < 0) {
    return res->fetch_all();  
  } else {
    return res->fetch(n);
  }
}

// [[Rcpp::export]]
bool rsqlite_has_completed(XPtr<SqliteResult> res) {
  if (R_ExternalPtrAddr(res) == NULL) stop("Results closed");
  
  return res->complete();
}


// [[Rcpp::export]]
int rsqlite_row_count(XPtr<SqliteResult> res) {
  if (R_ExternalPtrAddr(res) == NULL) stop("Results closed");
  
  return res->nrows() - 1;
}
