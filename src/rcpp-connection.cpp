#include <Rcpp.h>
#include <RSQLite.h>
using namespace Rcpp;

// [[Rcpp::export]]
XPtr<SqliteConnection> rsqlite_connect(std::string path, bool allow_ext, 
                                       int flags, std::string vfs = "") {
  SqliteConnection* conn = new SqliteConnection(path, allow_ext, flags, vfs);
  return XPtr<SqliteConnection>(conn, true);
}

// [[Rcpp::export]]
void rsqlite_disconnect(XPtr<SqliteConnection> con) {
  if (R_ExternalPtrAddr(con) == NULL) stop("Connection already closed");
  
  SqliteConnection* conn = (SqliteConnection*) R_ExternalPtrAddr(con);
  delete conn;
  R_ClearExternalPtr(con);
}

// [[Rcpp::export]]
std::string rsqlite_get_exception(XPtr<SqliteConnection> con) {
  if (R_ExternalPtrAddr(con) == NULL) stop("Connection already closed");
  
  return con->getException();
}

// [[Rcpp::export]]
bool rsqlite_connection_valid(XPtr<SqliteConnection> con) {
  return R_ExternalPtrAddr(con) != NULL;
}

