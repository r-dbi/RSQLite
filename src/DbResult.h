#ifndef __RSQLSITE_SQLITE_RESULT__
#define __RSQLSITE_SQLITE_RESULT__

#include <boost/noncopyable.hpp>
#include <boost/scoped_ptr.hpp>

#include "DbConnection.h"

class SqliteResultImpl;

class DbResult : boost::noncopyable {
  DbConnectionPtr pConn_;
  boost::scoped_ptr<SqliteResultImpl> impl;

public:
  DbResult(const DbConnectionPtr& pConn, const std::string& sql);
  ~DbResult();

public:
  static DbResult* create_and_send_query(const DbConnectionPtr& con, const std::string& sql, bool is_statement);

public:
  bool complete();
  bool is_active() const;
  int n_rows_fetched();
  int n_rows_affected();

  void bind(const List& params);
  List fetch(int n_max = -1);

  List get_column_info();

public:
  CharacterVector get_placeholder_names() const;

private:
  void validate_params(const List& params) const;
};

#endif // __RSQLSITE_SQLITE_RESULT__
