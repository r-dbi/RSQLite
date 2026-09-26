#' @rdname SQLiteConnection-class
#' @param schema The Arrow types of some or all result columns,
#'   as a struct `nanoarrow_schema`, an arrow `Schema`,
#'   or a named list of column types such as `list(id = nanoarrow::na_int32())`,
#'   matched to the result columns by name, see [sqlite-arrow].
#'   The default `NULL` decides the types from the values.
#' @usage NULL
dbSendQueryArrow_SQLiteConnection <- function(conn, statement, params = NULL, ..., schema = NULL) {
  res <- dbSendQuery(conn, statement, params = params, ...)
  if (!is.null(schema)) {
    tryCatch(
      arrow_set_schema(res, schema),
      error = function(e) {
        dbClearResult(res)
        stop(e)
      }
    )
  }
  SQLiteResultArrow(res)
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbSendQueryArrow", "SQLiteConnection", dbSendQueryArrow_SQLiteConnection)
