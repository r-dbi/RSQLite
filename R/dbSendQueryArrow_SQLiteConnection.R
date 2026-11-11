#' @rdname SQLiteConnection-class
#' @usage NULL
dbSendQueryArrow_SQLiteConnection <- function(conn, statement, params = NULL, ...) {
  res <- dbSendQuery(conn, statement, params = params, ...)
  SQLiteResultArrow(res)
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbSendQueryArrow", "SQLiteConnection", dbSendQueryArrow_SQLiteConnection)
