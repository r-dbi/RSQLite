#include "pch.h"
#include "DbConnection.h"


DbConnection::DbConnection(const std::string& path, const bool allow_ext, const int flags, const std::string& vfs, bool with_alt_types)
  : pConn_(NULL), 
    with_alt_types_(with_alt_types),
    busy_callback_(NULL) {

  // Get the underlying database connection
  int rc = sqlite3_open_v2(path.c_str(), &pConn_, flags, vfs.size() ? vfs.c_str() : NULL);
  if (rc != SQLITE_OK) {
    stop("Could not connect to database:\n%s", getException());
  }
  if (allow_ext) {
    sqlite3_enable_load_extension(pConn_, 1);
  }
}

DbConnection::~DbConnection() {
  if (is_valid()) {
    disconnect();
  }
  // in case this is still lingering for an invalid connection
  release_callback_data();
}

sqlite3* DbConnection::conn() const {
  if (!is_valid()) stop("disconnected");
  return pConn_;
}

bool DbConnection::is_valid() const {
  return (pConn_ != NULL);
}

void DbConnection::set_current_result(const DbResult*) const {
}

void DbConnection::reset_current_result(const DbResult*) const {
}

bool DbConnection::is_current_result(const DbResult*) const {
  return true;
}

void DbConnection::check_connection() const {
  if (!is_valid()) {
    stop("Invalid or closed connection");
  }
}

std::string DbConnection::getException() const {
  if (is_valid())
    return std::string(sqlite3_errmsg(pConn_));
  else
    return std::string();
}

void DbConnection::copy_to(const DbConnectionPtr& pDest) {
  sqlite3_backup* backup =
    sqlite3_backup_init(pDest->conn(), "main", pConn_, "main");

  int rc = sqlite3_backup_step(backup, -1);
  if (rc != SQLITE_DONE) {
    stop("Failed to copy all data:\n%s", getException());
  }
  rc = sqlite3_backup_finish(backup);
  if (rc != SQLITE_OK) {
    stop("Could not finish copy:\n%s", getException());
  }
}

void DbConnection::disconnect() {
  sqlite3_close_v2(pConn_);
  pConn_ = NULL;
  release_callback_data();
}

bool DbConnection::with_alt_types() const {
  return with_alt_types_;
}

void DbConnection::set_busy_handler(SEXP r_callback) {
  check_connection();
  if (busy_callback_) {
    R_ReleaseObject(busy_callback_);
    busy_callback_ = NULL;
  }

  if (! Rf_isNull(r_callback)) {
    R_PreserveObject(r_callback);
    busy_callback_ = r_callback;
  }

  if (busy_callback_ && Rf_isInteger(busy_callback_)) {
    sqlite3_busy_timeout(pConn_, INTEGER(busy_callback_)[0]);
  } else {
    sqlite3_busy_handler(pConn_, busy_callback_helper, busy_callback_);
  }
}

void DbConnection::release_callback_data() {
  if (busy_callback_) {
    R_ReleaseObject(busy_callback_);
    busy_callback_ = NULL;
  }
}

int DbConnection::busy_callback_helper(void *data, int num)
{
  SEXP r_callback = reinterpret_cast<SEXP>(data);

  // Overarching safety net
  try
  {
    try
    {
      Function rfun = r_callback;
      IntegerVector ret = rfun(num);
      return as<int>(ret);
    }
    catch (eval_error &e)
    {
      Rcpp::message("Busy callback failed, aborting transaction: %s", e.what());
      return 0;
    }
    catch (Rcpp::internal::InterruptedException &e)
    {
      // Not warning on explicit interrupt
      return 0;
    }
    catch (...)
    {
      Rcpp::message("Busy callback failed, aborting transaction");
      return 0;
    }
  }
  catch (...)
  {
    return 0;
  }
}
