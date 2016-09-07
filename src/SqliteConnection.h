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
class SqliteConnection;
typedef boost::shared_ptr<SqliteConnection> SqliteConnectionPtr;

class SqliteConnection : boost::noncopyable {
public:
  // Create a new connection handle
  SqliteConnection(const std::string& path, bool allow_ext,
                   int flags, const std::string& vfs = "");
  virtual ~SqliteConnection();

public:
  // Get access to the underlying sqlite3*
  sqlite3* conn() const {
    return pConn_;
  }

public:
  // Get the last exception code
  int getExceptionCode() const;

  // Get the last exception as a string
  std::string getException() const;

public:
  // Copies a database
  void copy_to(SqliteConnectionPtr pDest);

private:
  sqlite3* pConn_;
};

#endif // __RSQLSITE_SQLITE_CONNECTION__
