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

// The external pointer owns a shared pointer to the result,
// as that of a connection owns one to the connection.
// It is R's share of the result, dropped by dbClearResult() or the finalizer.
[[cpp11::register]]
cpp11::external_pointer<DbResultPtr> result_create(
  cpp11::external_pointer<DbConnectionPtr> con,
  std::string sql
) {
  (*con)->check_connection();
  DbResultPtr* res =
    new DbResultPtr(SqliteResult::create_and_send_query(*con, sql));
  return cpp11::external_pointer<DbResultPtr>(res, true);
}

[[cpp11::register]]
void result_release(cpp11::external_pointer<DbResultPtr> res) {
  DbResultPtr* ptr = res.get();
  if (ptr != NULL && ptr->get() != NULL && (*ptr)->busy()) {
    // Freeing it would pull the statement from under the running fetch
    cpp11::stop(
      "Can't clear a result while one of its fetches or binds is running, "
      "as from a handler of a warning that it raised."
    );
  }
  res.reset();
}

[[cpp11::register]]
bool result_valid(cpp11::external_pointer<DbResultPtr> res_) {
  DbResultPtr* res = res_.get();
  return res != NULL && res->get() != NULL && (*res)->is_active();
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
