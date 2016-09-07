#ifndef __RSQLSITE_SQLITE_RESULT__
#define __RSQLSITE_SQLITE_RESULT__

#include <Rcpp.h>
#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include "sqlite3/sqlite3.h"

#include "SqliteConnection.h"
#include "SqliteUtils.h"

class SqliteResult : boost::noncopyable {
  sqlite3_stmt* pStatement_;
  SqliteConnectionPtr pConn_;
  bool complete_, ready_;
  int nrows_, ncols_, rows_affected_, nparams_;
  std::vector<SEXPTYPE> types_;
  std::vector<std::string> names_;

public:
  SqliteResult(const SqliteConnectionPtr& pConn, const std::string& sql);
  virtual ~SqliteResult();

public:
  bool complete() {
    return complete_;
  }

  int nrows() {
    return nrows_;
  }

  int rows_affected() {
    return rows_affected_;
  }

public:
  void bind(const Rcpp::List& params);
  void bind_rows(const Rcpp::List& params);
  Rcpp::List fetch(int n_max = -1);
  Rcpp::List column_info();

private:
  void init();
  void step();
  void cache_field_data();

  Rcpp::List fetch_rows(int n_max, int& n);
  Rcpp::List peek_first_row();

  void set_col_values(Rcpp::List& out, const int i, const int n);
  SEXP set_col_value(SEXP col, const int i, const int j, const int n);
  SEXP alloc_col(const SEXPTYPE type, const int i, const int n);
  void fill_default_col_value(SEXP col, const int i, const SEXPTYPE type);
  void set_raw_value(SEXP col, const int i, const int j);

  static SEXPTYPE datatype_to_sexptype(const int field_type);
  static SEXPTYPE decltype_to_sexptype(const char* decl_type);
};

#endif // __RSQLSITE_SQLITE_RESULT__
