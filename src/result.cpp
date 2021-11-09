#define STRICT_R_HEADERS
#define R_NO_REMAP

#include "pch.h"
#include "RSQLite_types.h"

//#include "DbResult.h"


[[cpp11::register]]
cpp11::external_pointer<DbResult> result_create(cpp11::external_pointer<DbConnectionPtr> con, std::string sql) {
  (*con)->check_connection();
  DbResult* res = SqliteResult::create_and_send_query(*con, sql);
  return cpp11::external_pointer<DbResult>(res, true);
}

template <typename T, void Finalizer(T*) >
void finalizer_wrapper(SEXP p) {
    if (TYPEOF(p) != EXTPTRSXP)
        return;

    T* ptr = (T*) R_ExternalPtrAddr(p);
    // RCPP_DEBUG_3("finalizer_wrapper<%s>(SEXP p = <%p>). ptr = %p", DEMANGLE(T), p, ptr)

    if (ptr == NULL)
        return;

    // Clear before finalizing to avoid behavior like access of freed memory
    R_ClearExternalPtr(p);

    Finalizer(ptr);
}

template <typename T>
void standard_delete_finalizer(T* obj) {												// #nocov start
    delete obj;
}

template <typename T>
void release(SEXP x) {
  if (x != NULL) {
    // Call the finalizer -- note that this implies that finalizers
    // need to be ready for a NULL external pointer value (our
    // default C++ finalizer is since delete NULL is a no-op).
    // This clears the external pointer just before calling the finalizer,
    // to avoid interesting behavior with co-dependent finalizers.
    finalizer_wrapper<T,standard_delete_finalizer<T>>(x);
  }
}

[[cpp11::register]]
void result_release(cpp11::sexp res) {
  // TODO
  release<DbResult>(res);
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
