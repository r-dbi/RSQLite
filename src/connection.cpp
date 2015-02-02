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

  int n = con->use_count();
  if (n > 1) {
    Rcout << "There are " << n - 1 << " result objects in use.\n" <<
      "The connection will be automatically released when they are closed\n";
  } 
  
  con.release();
}

// [[Rcpp::export]]
std::string rsqlite_get_exception(XPtr<SqliteConnectionPtr> con) {
  return (*con)->getException();
}

// [[Rcpp::export]]
void rsqlite_copy_database(XPtr<SqliteConnectionPtr> from, 
                           XPtr<SqliteConnectionPtr> to) {
  (*from)->copy_to((*to));
}

// [[Rcpp::export]]
bool rsqlite_connection_valid(XPtr<SqliteConnectionPtr> con) {
  return con;
}

