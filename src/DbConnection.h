#ifndef __RSQLSITE_SQLITE_CONNECTION__
#define __RSQLSITE_SQLITE_CONNECTION__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include "sqlite3.h"

// Connection ------------------------------------------------------------------

// Reference counted wrapper for a sqlite3* connnection which will keep the
// connection alive as long as there are references to this object alive.

// convenience typedef for shared_ptr to DbConnectionWrapper
class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;

class DbConnection : boost::noncopyable {
public:
  // Create a new connection handle
  DbConnection(const std::string& path, bool allow_ext,
               int flags, const std::string& vfs = "");
  ~DbConnection();

public:
  // Get access to the underlying sqlite3*
  sqlite3* conn() const;

  // Is the connection valid?
  bool is_valid() const;

  // Fail if the connection is invalid
  void check_connection() const;

  // Get the last exception as a string
  std::string getException() const;

  // Copies a database
  void copy_to(const DbConnectionPtr& pDest);

  // Disconnects from a database
  void disconnect();

private:
  sqlite3* pConn_;
};

#endif // __RSQLSITE_SQLITE_CONNECTION__
