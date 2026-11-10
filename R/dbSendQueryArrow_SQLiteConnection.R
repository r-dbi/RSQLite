#' @rdname SQLiteConnection-class
#' @param schema The Arrow types of some or all result columns,
#'   as a struct `nanoarrow_schema`, an arrow `Schema`,
#'   or a named list of column types such as `list(id = nanoarrow::na_int32())`,
#'   matched to the result columns by name, see [sqlite-arrow].
#'   The default `NULL` decides the types from the values.
#' @usage NULL
dbSendQueryArrow_SQLiteConnection <- function(conn, statement, params = NULL, ..., schema = NULL) {
  # Evaluated and checked before the query is sent, so that an error leaves no
  # result open; the names and types need the result's columns
  if (!is.null(schema)) {
    # The `ptype` of dbSendQuery() would stay on the result while the schema
    # replaced its types, and data frame fetches would convert to the prototype
    if (!is.null(list(...)[["ptype"]])) {
      stopc("`schema` and `ptype` can't be combined, use one of them")
    }
    schema <- arrow_check_schema(schema)
  }
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
