#include "pch.h"
#include "RSQLite_types.h"

// #include "DbResult.h"

// An integer while it fits, a double beyond INT_MAX, where R integers end
static SEXP row_count_as_sexp(int64_t n) {
  if (n <= INT_MAX) {
    return cpp11::as_sexp(static_cast<int>(n));
  }
  return cpp11::as_sexp(static_cast<double>(n));
}

[[cpp11::register]]
cpp11::external_pointer<DbResult> result_create(
  cpp11::external_pointer<DbConnectionPtr> con,
  std::string sql
) {
  (*con)->check_connection();
  DbResult* res = SqliteResult::create_and_send_query(*con, sql);
  return cpp11::external_pointer<DbResult>(res, true);
}

[[cpp11::register]]
void result_release(cpp11::external_pointer<DbResult> res) {
  res.reset();
}

[[cpp11::register]]
bool result_valid(cpp11::external_pointer<DbResult> res_) {
  DbResult* res = res_.get();
  return res != NULL && res->is_active();
}

[[cpp11::register]]
cpp11::list result_fetch(DbResult* res, const int n) {
  return res->fetch(n);
}

[[cpp11::register]]
void result_bind(DbResult* res, cpp11::list params) {
  res->bind(params);
}

[[cpp11::register]]
bool result_has_completed(DbResult* res) {
  return res->complete();
}

[[cpp11::register]]
SEXP result_rows_fetched(DbResult* res) {
  return row_count_as_sexp(res->n_rows_fetched());
}

[[cpp11::register]]
SEXP result_rows_affected(DbResult* res) {
  return row_count_as_sexp(res->n_rows_affected());
}

[[cpp11::register]]
cpp11::list result_column_info(DbResult* res) {
  return res->get_column_info();
}

[[cpp11::register]]
cpp11::strings result_get_placeholder_names(SqliteResult* res) {
  return res->get_placeholder_names();
}

// For the tests: sets the number of rows fetched from the statement
[[cpp11::register]]
void result_set_rows_fetched(SqliteResult* res, double n) {
  res->set_rows_fetched(static_cast<int64_t>(n));
}

// For the tests: sets the number of rows the statement has changed so far
[[cpp11::register]]
void result_set_rows_affected(SqliteResult* res, double n) {
  res->set_rows_affected(static_cast<int64_t>(n));
}
