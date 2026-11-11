#include "pch.h"
#include "SqliteResult.h"
#include "SqliteResultImpl.h"

// Construction ////////////////////////////////////////////////////////////////

SqliteResult::SqliteResult(const DbConnectionPtr& pConn, const std::string& sql)
    : DbResult(pConn) {
  impl.reset(new DbResultImpl(pConn, sql));
}

DbResult* SqliteResult::create_and_send_query(
  const DbConnectionPtr& con,
  const std::string& sql
) {
  return new SqliteResult(con, sql);
}

// Publics /////////////////////////////////////////////////////////////////////

cpp11::strings SqliteResult::get_placeholder_names() const {
  return impl->get_placeholder_names();
}

void SqliteResult::set_rows_fetched(int64_t n) {
  impl->set_rows_fetched(n);
}

void SqliteResult::set_arrow_bytes_limits(
  int64_t cut_bytes,
  int64_t max_bytes
) {
  impl->set_arrow_bytes_limits(cut_bytes, max_bytes);
}
