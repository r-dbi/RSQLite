//
// Created by muelleki on 30.09.16.
//

#ifndef RSQLITE_SQLITERESULTIMPL_H
#define RSQLITE_SQLITERESULTIMPL_H


#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include "sqlite3/sqlite3.h"

class SqliteResultImpl {
private:
  sqlite3_stmt* pStatement_;
  bool complete_;
  bool ready_;
  int nrows_;
  int ncols_;
  int rows_affected_;
  int nparams_;
  std::vector<SEXPTYPE> types_;
  std::vector<std::string> names_;

public:
  void prepare(const std::__cxx11::string& sql);

  void init_if_bound();

  void init();

  void cache_field_data();

  void bind_impl(const Vector<19>& params);

  void bind_rows_impl(const Vector<19>& params);

  void bind_parameter(int i, int j, const std::__cxx11::string& name, struct SEXPREC* values_);

  Vector<13> find_params_impl(const Vector<16>& param_names);

  int find_parameter(const std::__cxx11::string& name);

  void bind_parameter_pos(int i, int j, struct SEXPREC* value_);

  Vector<19> fetch_impl(const int n_max);

  Vector<19> fetch_rows(int n_max, int& n);

  void step();

  Vector<19> peek_first_row();

  Vector<19> alloc_missing_cols(Vector<19> data, int n);

  void set_col_values(Vector<19>& out, const int i, const int n);

  void set_col_value(struct SEXPREC*& col, const int i, const int j, const int n);

  struct SEXPREC* alloc_col(const unsigned int type, const int i, const int n);

  void fill_default_col_value(struct SEXPREC* col, const int i, const unsigned int type);

  void fill_col_value(const struct SEXPREC* col, const int i, const int j,
                      unsigned int type);

  void set_raw_value(struct SEXPREC* col, const int i, const int j);

  Vector<19> get_column_info_impl();

  static unsigned int datatype_to_sexptype(const int field_type);

  static unsigned int decltype_to_sexptype(const char* decl_type);

public:
  ~SqliteResultImpl();
};


#endif //RSQLITE_SQLITERESULTIMPL_H
