#include <Rcpp.h>
#include "RSQLite.h"
using namespace Rcpp;

// [[Rcpp::export]]
XPtr<SqliteConnectionPtr> rsqlite_connect(std::string path, bool allow_ext, 
                                          int flags, std::string vfs = "") {
  
  SqliteConnectionPtr* pConn = new SqliteConnectionPtr(
    new SqliteConnectionWrapper(path, allow_ext, flags, vfs)
  );
  
  return XPtr<SqliteConnectionPtr>(pConn, true);
}

// [[Rcpp::export]]
void rsqlite_disconnect(XPtr<SqliteConnectionPtr> con) {
  if (R_ExternalPtrAddr(con) == NULL) stop("Connection already closed");
  
  int n = con->use_count();
  if (n > 1) {
    Rcout << "There are " << n - 1 << " result objects in use.\n" <<
      "The connection will be automatically released when they are closed\n";
  } 
  
  delete con.operator->();
  R_ClearExternalPtr(con);
}

// [[Rcpp::export]]
std::string rsqlite_get_exception(XPtr<SqliteConnectionPtr> con) {
  if (R_ExternalPtrAddr(con) == NULL) stop("Connection already closed");
  
  return (*con)->getException();
}

// [[Rcpp::export]]
void rsqlite_copy_database(XPtr<SqliteConnectionPtr> from, 
                           XPtr<SqliteConnectionPtr> to) {
  if (R_ExternalPtrAddr(from) == NULL) stop("From connection expired");
  if (R_ExternalPtrAddr(to) == NULL) stop("To connection expired");
  
  (*from)->copy_to((*to));
}

// [[Rcpp::export]]
bool rsqlite_connection_valid(XPtr<SqliteConnectionPtr> con) {
  return R_ExternalPtrAddr(con) != NULL;
}

