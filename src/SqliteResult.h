#ifndef __RSQLSITE_SQLITE_RESULT__
#define __RSQLSITE_SQLITE_RESULT__

#include <boost/noncopyable.hpp>
#include <boost/scoped_ptr.hpp>

#include "SqliteConnection.h"

class SqliteResultImpl;

class SqliteResult : boost::noncopyable {
  SqliteConnectionPtr pConn_;
  boost::scoped_ptr<SqliteResultImpl> impl;

public:
  SqliteResult(const SqliteConnectionPtr& pConn, const std::string& sql);
  ~SqliteResult();

public:
  bool complete();
  int nrows();
  int rows_affected();
  IntegerVector find_params(const CharacterVector& param_names);
  void bind(const List& params);
  void bind_rows(const List& params);
  List fetch(int n_max = -1);
  List get_column_info();

private:
  void validate_params(const List& params) const;
};

#endif // __RSQLSITE_SQLITE_RESULT__
