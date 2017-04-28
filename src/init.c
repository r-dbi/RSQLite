#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> // for NULL
#include <R_ext/Rdynload.h>

/* FIXME:
  Check these declarations against the C/Fortran source code.
*/

  /* .Call calls */
  extern SEXP RSQLite_init_logging(SEXP);
extern SEXP RSQLite_rsqlite_bind_rows(SEXP, SEXP);
extern SEXP RSQLite_rsqlite_clear_result(SEXP);
extern SEXP RSQLite_rsqlite_column_info(SEXP);
extern SEXP RSQLite_rsqlite_connect(SEXP, SEXP, SEXP, SEXP);
extern SEXP RSQLite_rsqlite_connection_valid(SEXP);
extern SEXP RSQLite_rsqlite_copy_database(SEXP, SEXP);
extern SEXP RSQLite_rsqlite_disconnect(SEXP);
extern SEXP RSQLite_rsqlite_fetch(SEXP, SEXP);
extern SEXP RSQLite_rsqlite_find_params(SEXP, SEXP);
extern SEXP RSQLite_rsqlite_has_completed(SEXP);
extern SEXP RSQLite_rsqlite_import_file(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP RSQLite_rsqlite_result_valid(SEXP);
extern SEXP RSQLite_rsqlite_row_count(SEXP);
extern SEXP RSQLite_rsqlite_rows_affected(SEXP);
extern SEXP RSQLite_rsqlite_send_query(SEXP, SEXP);
extern SEXP RSQLite_rsqliteVersion();

static const R_CallMethodDef CallEntries[] = {
  {"RSQLite_init_logging",             (DL_FUNC) &RSQLite_init_logging,             1},
  {"RSQLite_rsqlite_bind_rows",        (DL_FUNC) &RSQLite_rsqlite_bind_rows,        2},
  {"RSQLite_rsqlite_clear_result",     (DL_FUNC) &RSQLite_rsqlite_clear_result,     1},
  {"RSQLite_rsqlite_column_info",      (DL_FUNC) &RSQLite_rsqlite_column_info,      1},
  {"RSQLite_rsqlite_connect",          (DL_FUNC) &RSQLite_rsqlite_connect,          4},
  {"RSQLite_rsqlite_connection_valid", (DL_FUNC) &RSQLite_rsqlite_connection_valid, 1},
  {"RSQLite_rsqlite_copy_database",    (DL_FUNC) &RSQLite_rsqlite_copy_database,    2},
  {"RSQLite_rsqlite_disconnect",       (DL_FUNC) &RSQLite_rsqlite_disconnect,       1},
  {"RSQLite_rsqlite_fetch",            (DL_FUNC) &RSQLite_rsqlite_fetch,            2},
  {"RSQLite_rsqlite_find_params",      (DL_FUNC) &RSQLite_rsqlite_find_params,      2},
  {"RSQLite_rsqlite_has_completed",    (DL_FUNC) &RSQLite_rsqlite_has_completed,    1},
  {"RSQLite_rsqlite_import_file",      (DL_FUNC) &RSQLite_rsqlite_import_file,      6},
  {"RSQLite_rsqlite_result_valid",     (DL_FUNC) &RSQLite_rsqlite_result_valid,     1},
  {"RSQLite_rsqlite_row_count",        (DL_FUNC) &RSQLite_rsqlite_row_count,        1},
  {"RSQLite_rsqlite_rows_affected",    (DL_FUNC) &RSQLite_rsqlite_rows_affected,    1},
  {"RSQLite_rsqlite_send_query",       (DL_FUNC) &RSQLite_rsqlite_send_query,       2},
  {"RSQLite_rsqliteVersion",           (DL_FUNC) &RSQLite_rsqliteVersion,           0},
  {NULL, NULL, 0}
};

void R_init_RSQLite(DllInfo *dll)
{
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}
