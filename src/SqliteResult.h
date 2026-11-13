#ifndef __RSQLITE_SQLITE_RESULT__
#define __RSQLITE_SQLITE_RESULT__

#include <cpp11.hpp>
#include "DbResult.h"

// DbResult --------------------------------------------------------------------

class SqliteResult : public DbResult {
protected:
  SqliteResult(const DbConnectionPtr& pConn, const std::string& sql);

public:
  static DbResult* create_and_send_query(
    const DbConnectionPtr& con,
    const std::string& sql
  );

public:
  cpp11::strings get_placeholder_names() const;
  // For the tests
  void set_arrow_max_bytes(int64_t max_bytes);
  void set_rows_fetched(int64_t n);
  void set_rows_affected(int64_t n);
};

#endif
