#include <Rcpp.h>
#include "sqlite3.h"

class SqliteConnection {
  sqlite3* pConn_;
  
public:
  SqliteConnection(std::string path, bool allow_ext, int flags, std::string vfs = "") {
    int rc = sqlite3_open_v2(path.c_str(), &pConn_, flags, vfs.size() ? vfs.c_str() : NULL);
    if (rc != SQLITE_OK) {
      Rcpp::stop("Could not connect to database:\n%s", sqlite3_errmsg(pConn_));
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
    
// Prevent copying because of shared resource
private:
  SqliteConnection( SqliteConnection const& );
  SqliteConnection operator=( SqliteConnection const& );
  
};
