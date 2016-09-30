#include <RSQLite.h>
#include <workarounds/XPtr.h>
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
XPtr<SqliteConnectionPtr> rsqlite_connect(
  const std::string& path, bool allow_ext, int flags, const std::string& vfs = "")
{

  SqliteConnectionPtr* pConn = new SqliteConnectionPtr(
    new SqliteConnection(path, allow_ext, flags, vfs)
  );

  return XPtr<SqliteConnectionPtr>(pConn, true);
}

// [[Rcpp::export]]
void rsqlite_disconnect(XPtr<SqliteConnectionPtr>& con) {
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
void rsqlite_copy_database(const XPtr<SqliteConnectionPtr>& from,
                           const XPtr<SqliteConnectionPtr>& to) {
  (*from)->copy_to((*to));
}

// [[Rcpp::export]]
bool rsqlite_connection_valid(const XPtr<SqliteConnectionPtr>& con) {
  return con.get() != NULL;
}

// [[Rcpp::export]]
bool rsqlite_import_file(const XPtr<SqliteConnectionPtr>& con,
                         const std::string& name, const std::string& value,
                         const std::string& sep, const std::string& eol,
                         int skip) {
  return !!RS_sqlite_import(con->get()->conn(), name.c_str(), value.c_str(),
                            sep.c_str(), eol.c_str(), skip);
}
