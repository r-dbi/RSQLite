#include "pch.h"
#include "RSQLite_types.h"
#include "DbArrow.h"
// After DbArrow.h, so that the Arrow C structs are defined once
#include <nanoarrow/r.h>
#include <cmath>

// #include "DbResult.h"

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

// At most `n` rows, all of them for -1, as a nanoarrow_array of a struct type,
// with one warning about the values converted to the type of their column.
// A chunk kept because that warning exited comes whole with the next call,
// whatever its `n`.
// Internal for now: no DBI method calls it yet.
[[cpp11::register]]
SEXP result_fetch_arrow_chunk(DbResult* res, const int n) {
  if (n == 0 || n < -1) {
    cpp11::stop("`n` must be positive, or -1 for all rows.");
  }
  // Allocated before the fetch, so that a failed allocation loses no rows
  cpp11::sexp array_xptr(cpp11::safe[nanoarrow_array_owning_xptr]());
  cpp11::sexp schema_xptr(cpp11::safe[nanoarrow_schema_owning_xptr]());
  res->fetch_arrow_chunk(
    nanoarrow_output_array_from_xptr(array_xptr),
    nanoarrow_output_schema_from_xptr(schema_xptr),
    n
  );
  // The schema of a nanoarrow_array lives in the tag of the external pointer
  R_SetExternalPtrTag(array_xptr, schema_xptr);
  return array_xptr;
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
int result_rows_fetched(DbResult* res) {
  return res->n_rows_fetched();
}

[[cpp11::register]]
int result_rows_affected(DbResult* res) {
  return res->n_rows_affected();
}

[[cpp11::register]]
cpp11::list result_column_info(DbResult* res) {
  return res->get_column_info();
}

[[cpp11::register]]
cpp11::strings result_get_placeholder_names(SqliteResult* res) {
  return res->get_placeholder_names();
}

// For the tests: lowers the bytes of text or blobs that a utf8 or binary
// column of an Arrow chunk of `res` holds, from the 2^31 - 1 that their
// 32-bit offsets address, so that the tests of the limit need little memory
[[cpp11::register]]
void result_set_arrow_max_bytes(SqliteResult* res, double max_bytes) {
  if (!(max_bytes >= 0 && max_bytes <= INT32_MAX &&
        max_bytes == std::floor(max_bytes))) {
    cpp11::stop("`max_bytes` must be a whole number between 0 and 2^31 - 1.");
  }
  res->set_arrow_max_bytes(static_cast<int64_t>(max_bytes));
}
