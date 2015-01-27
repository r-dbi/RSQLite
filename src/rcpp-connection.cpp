#include <Rcpp.h>
#include <RSQLite.h>
using namespace Rcpp;

// [[Rcpp::export]]
XPtr<SqliteConnection> rsqlite_connect(std::string path, bool allow_ext, 
                                       int flags, std::string vfs = "") {
  SqliteConnection* conn = new SqliteConnection(path, allow_ext, flags, vfs);
  return XPtr<SqliteConnection>(conn, true);
}
