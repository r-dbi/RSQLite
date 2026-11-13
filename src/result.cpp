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

// For the tests: a count of rows from R.
// The cast to int64_t is undefined for a value that it can't hold,
// so the range is checked first; the check also fails for NA and NaN.
static int64_t row_count_from_double(double n) {
  if (!(n >= 0 && n <= 9007199254740992.0) ||
      static_cast<double>(static_cast<int64_t>(n)) != n) {
    cpp11::stop("`n` must be a whole number from 0 to 2^53.");
  }
  return static_cast<int64_t>(n);
}

// For the tests: sets the number of rows fetched from the statement
[[cpp11::register]]
void result_set_rows_fetched(SqliteResult* res, double n) {
  res->set_rows_fetched(row_count_from_double(n));
}

// For the tests: sets the number of rows the statement has changed so far
[[cpp11::register]]
void result_set_rows_affected(SqliteResult* res, double n) {
  res->set_rows_affected(row_count_from_double(n));
}
