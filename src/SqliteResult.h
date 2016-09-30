#ifndef __RSQLSITE_SQLITE_RESULT__
#define __RSQLSITE_SQLITE_RESULT__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>

#include "SqliteConnection.h"

class SqliteResult : boost::noncopyable {
  SqliteConnectionPtr pConn_;

public:
  SqliteResult(const SqliteConnectionPtr& pConn, const std::string& sql);

public:
  bool complete();
  int nrows();
  int rows_affected();
  IntegerVector find_params(const CharacterVector& param_names);
  void bind(const List& params);
  void bind_rows(const List& params);
  List fetch(int n_max = -1);
  List get_column_info();

};

#endif // __RSQLSITE_SQLITE_RESULT__
