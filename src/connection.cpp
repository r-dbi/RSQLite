#include <Rcpp.h>
#include <RSQLite.h>
using namespace Rcpp;

// [[Rcpp::export]]
XPtr<SqliteConnectionWrapper> rsqlite_connect(std::string path, bool allow_ext, 
                                       int flags, std::string vfs = "") {
  SqliteConnectionWrapper* conn = new SqliteConnectionWrapper(path, allow_ext, flags, vfs);
  return XPtr<SqliteConnectionWrapper>(conn, true);
}

// [[Rcpp::export]]
void rsqlite_disconnect(XPtr<SqliteConnectionWrapper> con) {
  if (R_ExternalPtrAddr(con) == NULL) stop("Connection already closed");
  
  delete (SqliteConnectionWrapper*) con;
  R_ClearExternalPtr(con);
}

// [[Rcpp::export]]
std::string rsqlite_get_exception(XPtr<SqliteConnectionWrapper> con) {
  if (R_ExternalPtrAddr(con) == NULL) stop("Connection already closed");
  
  return con->pConn->getException();
}

// [[Rcpp::export]]
void rsqlite_copy_database(XPtr<SqliteConnectionWrapper> from, 
                           XPtr<SqliteConnectionWrapper> to) {
  if (R_ExternalPtrAddr(from) == NULL) stop("From connection expired");
  if (R_ExternalPtrAddr(to) == NULL) stop("To connection expired");
  
  from->pConn->copy_to(to->pConn);
}

// [[Rcpp::export]]
bool rsqlite_connection_valid(XPtr<SqliteConnectionWrapper> con) {
  return R_ExternalPtrAddr(con) != NULL;
}

