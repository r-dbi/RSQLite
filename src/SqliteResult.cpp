#include "pch.h"
#include "SqliteResult.h"
#include "SqliteResultImpl.h"



// Construction ////////////////////////////////////////////////////////////////

SqliteResult::SqliteResult(const DbConnectionPtr& pConn, const std::string& sql) :
  DbResult(pConn)
{
  impl.reset(new DbResultImpl(pConn, sql));
}


DbResult* SqliteResult::create_and_send_query(const DbConnectionPtr& con, const std::string& sql) {
  return new SqliteResult(con, sql);
}

// Publics /////////////////////////////////////////////////////////////////////

CharacterVector SqliteResult::get_placeholder_names() const {
  return impl->get_placeholder_names();
}
