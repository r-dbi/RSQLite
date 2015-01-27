#include <Rcpp.h>
#include "sqlite3.h"

class SqliteResult;

// Connection ------------------------------------------------------------------

class SqliteConnection {
  friend class SqliteResult;
  sqlite3* pConn_;

public:
    SqliteConnection(std::string path, bool allow_ext, int flags, std::string vfs = "") {
    int rc = sqlite3_open_v2(path.c_str(), &pConn_, flags, vfs.size() ? vfs.c_str() : NULL);
    if (rc != SQLITE_OK) {
      Rcpp::stop("Could not connect to database:\n%s", getException());
    }
    if (allow_ext) {
      sqlite3_enable_load_extension(pConn_, 1);
    }
  }
  
  virtual ~SqliteConnection() {
    try {
      sqlite3_close_v2(pConn_); 
    } catch(...) {}
  }

  std::string getException() const {
    return std::string(sqlite3_errmsg(pConn_));
  }
    
// Prevent copying because of shared resource
private:
  SqliteConnection( SqliteConnection const& );
  SqliteConnection operator=( SqliteConnection const& );
  
};

// Result ----------------------------------------------------------------------

class SqliteResult {
  sqlite3_stmt* pStatement_;
  
public:
  SqliteResult(SqliteConnection* con, std::string sql) {
    int rc = sqlite3_prepare_v2(con->pConn_, sql.c_str(), sql.size() + 1, 
      &pStatement_, NULL);
    
    if (rc != SQLITE_OK) {
      Rcpp::stop("Could not send query:\n%s", con->getException());
    }
  }
  
  virtual ~SqliteResult() {
    try {
      sqlite3_finalize(pStatement_); 
    } catch(...) {}
  }
  
  // Prevent copying because of shared resource
private:
  SqliteResult( SqliteResult const& );
  SqliteResult operator=( SqliteResult const& );
  
};


