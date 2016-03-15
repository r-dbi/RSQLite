#ifndef __RSQLSITE_SQLITE_CONNECTION__
#define __RSQLSITE_SQLITE_CONNECTION__

#include <Rcpp.h>
#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include "sqlite3/sqlite3.h"

#include "SqliteUtils.h"

// Connection ------------------------------------------------------------------

// Reference counted wrapper for a sqlite3* connnection which will keep the
// connection alive as long as there are references to this object alive.

// convenience typedef for shared_ptr to SqliteConnectionWrapper
class SqliteConnectionWrapper;
typedef boost::shared_ptr<SqliteConnectionWrapper> SqliteConnectionPtr;

class SqliteConnectionWrapper : boost::noncopyable {
public:
  // Create a new connection handle
  SqliteConnectionWrapper(std::string path, bool allow_ext, 
                          int flags, std::string vfs = "")
    : pConn_(NULL) {
    
    // Get the underlying database connection
    int rc = sqlite3_open_v2(path.c_str(), &pConn_, flags, vfs.size() ? vfs.c_str() : NULL);
    if (rc != SQLITE_OK) {
      Rcpp::stop("Could not connect to database:\n%s", getException());
    }
    if (allow_ext) {
      sqlite3_enable_load_extension(pConn_, 1);
    }
  }
  
  void copy_to(SqliteConnectionPtr pDest) {
    sqlite3_backup* backup = sqlite3_backup_init(pDest->conn(), "main", 
                                                 pConn_, "main");
    
    int rc = sqlite3_backup_step(backup, -1);
    if (rc != SQLITE_DONE) {
      Rcpp::stop("Failed to copy all data:\n%s", getException());
    }
    rc = sqlite3_backup_finish(backup);
    if (rc != SQLITE_OK) {
      Rcpp::stop("Could not finish copy:\n%s", getException());
    }
  }
  
  virtual ~SqliteConnectionWrapper() {
    try {
      sqlite3_close_v2(pConn_); 
    } catch(...) {}
  }
  
  
  // Get access to the underlying sqlite3*
  sqlite3* conn() const { return pConn_; }
  
  // Get the last exception as a string
  std::string getException() const {
    if (pConn_ != NULL)
      return std::string(sqlite3_errmsg(pConn_));
    else
      return std::string();
  }
  
private:
  sqlite3* pConn_;
};

#endif // __RSQLSITE_SQLITE_CONNECTION__
