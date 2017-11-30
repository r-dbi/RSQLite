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
  bool complete();
  int n_rows_fetched();
  int n_rows_affected();
  CharacterVector get_placeholder_names() const;

  void bind(const List& params);
  List fetch(int n_max = -1);
  List get_column_info();

private:
  void validate_params(const List& params) const;
};

#endif // __RSQLSITE_SQLITE_RESULT__
