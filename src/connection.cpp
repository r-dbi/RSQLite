#include <Rcpp.h>
#include "SqliteConnection.h"
using namespace Rcpp;

extern "C" {
  int RS_sqlite_import(
    sqlite3* db,
    const char* zTable,          /* table must already exist */
    const char* zFile,
    const char* separator,
    const char* eol,
    int skip
  );
}

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
    warning(
      "There are %i result in use. The connection will be released when they are closed",
      n - 1
    );
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
  return con.get() != NULL;
}

// [[Rcpp::export]]
bool rsqlite_import_file(XPtr<SqliteConnectionPtr> con,
                         const std::string& name,
                         const std::string& value,
                         const std::string& sep,
                         const std::string& eol,
                         int skip) {
  SqliteConnectionPtr* con2 = con;
  SqliteConnectionWrapper* con3 = con2->get();
  return (bool)RS_sqlite_import(con3->conn(), name.c_str(), value.c_str(), sep.c_str(), eol.c_str(), skip);
}
