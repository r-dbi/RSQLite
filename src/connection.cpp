#include "pch.h"
#include <workarounds/XPtr.h>
#include "DbConnection.h"

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
XPtr<DbConnectionPtr> connection_connect(
  const std::string& path, const bool allow_ext, const int flags, const std::string& vfs = ""
) {
  LOG_VERBOSE;

  DbConnectionPtr* pConn = new DbConnectionPtr(
    new DbConnection(path, allow_ext, flags, vfs)
  );

  return XPtr<DbConnectionPtr>(pConn, true);
}

// [[Rcpp::export]]
bool connection_valid(XPtr<DbConnectionPtr> con_) {
  DbConnectionPtr* con = con_.get();
  return con && con->get()->is_valid();
}

// [[Rcpp::export]]
void connection_release(XPtr<DbConnectionPtr> con_) {
  if (!connection_valid(con_)) {
    warning("Already disconnected");
    return;
  }

  DbConnectionPtr* con = con_.get();
  long n = con_->use_count();
  if (n > 1) {
    warning(
      "There are %i result in use. The connection will be released when they are closed",
      n - 1
    );
  }

  con->get()->disconnect();
  // don't release here to make sure a nice error message is delivered
}


// Quoting


// Transactions

// Specific functions

// [[Rcpp::export]]
void connection_copy_database(const XPtr<DbConnectionPtr>& from,
                              const XPtr<DbConnectionPtr>& to) {
  (*from)->copy_to((*to));
}

// [[Rcpp::export]]
bool connection_import_file(const XPtr<DbConnectionPtr>& con,
                            const std::string& name, const std::string& value,
                            const std::string& sep, const std::string& eol,
                            const int skip) {
  return !!RS_sqlite_import(con->get()->conn(), name.c_str(), value.c_str(),
                            sep.c_str(), eol.c_str(), skip);
}

// as() override

namespace Rcpp {

template<>
DbConnection* as(SEXP x) {
  DbConnectionPtr* connection = (DbConnectionPtr*)(R_ExternalPtrAddr(x));
  if (!connection)
    stop("Invalid connection");
  return connection->get();
}

}
