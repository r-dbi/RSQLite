#include <Rcpp.h>
#include <RSQLite.h>
using namespace Rcpp;

// [[Rcpp::export]]
XPtr<SqliteConnection> rsqlite_connect(std::string path, int flags, std::string vfs = "") {
  SqliteConnection* conn = new SqliteConnection(path, flags, vfs);
  return XPtr<SqliteConnection>(conn, true);
}
