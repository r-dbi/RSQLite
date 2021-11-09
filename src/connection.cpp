#define STRICT_R_HEADERS
#define R_NO_REMAP

#include "pch.h"
#include "DbConnection.h"

namespace cpp11 {

template <typename T>
using enable_if_dbconnection_ptr = typename std::enable_if<
    std::is_same<DbConnectionPtr*, T>::value, T>::type;

template <typename T>
enable_if_dbconnection_ptr<T> as_cpp(SEXP x) {
  DbConnectionPtr* result = (DbConnectionPtr*)(R_ExternalPtrAddr(x));
  if (!result)
    cpp11::stop("Invalid result set");
  return result;
}

}  // namespace cpp11

#include <cpp11/R.hpp>

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

[[cpp11::register]]
cpp11::external_pointer<DbConnectionPtr> connection_connect(
  const std::string& path, const bool allow_ext, const int flags, const std::string& vfs = "", bool with_alt_types = false
) {
  LOG_VERBOSE;

  DbConnectionPtr* pConn = new DbConnectionPtr(
    new DbConnection(path, allow_ext, flags, vfs, with_alt_types)
  );

  return cpp11::external_pointer<DbConnectionPtr>(pConn, true);
}

[[cpp11::register]]
bool connection_valid(cpp11::external_pointer<DbConnectionPtr> con_) {
  DbConnectionPtr* con = con_.get();
  return con && con->get()->is_valid();
}

[[cpp11::register]]
void connection_release(cpp11::external_pointer<DbConnectionPtr> con_) {
  if (!connection_valid(con_)) {
    Rcpp::warning("Already disconnected");
    return;
  }

  DbConnectionPtr* con = con_.get();
  long n = con_->use_count();
  if (n > 1) {
    Rcpp::warning(
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

[[cpp11::register]]
void connection_copy_database(const cpp11::external_pointer<DbConnectionPtr>& from,
                              const cpp11::external_pointer<DbConnectionPtr>& to) {
  (*from.get())->copy_to(*to.get());
}

[[cpp11::register]]
bool connection_import_file(const cpp11::external_pointer<DbConnectionPtr>& con,
                            const std::string& name, const std::string& value,
                            const std::string& sep, const std::string& eol,
                            const int skip) {
  return !!RS_sqlite_import(con->get()->conn(), name.c_str(), value.c_str(),
                            sep.c_str(), eol.c_str(), skip);
}

[[cpp11::register]]
void set_busy_handler(const cpp11::external_pointer<DbConnectionPtr>& con, SEXP r_callback) {
  con->get()->set_busy_handler(r_callback);
}
