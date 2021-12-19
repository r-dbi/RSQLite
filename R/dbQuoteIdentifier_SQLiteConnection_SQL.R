#' @rdname SQLiteConnection-class
#' @usage NULL
dbQuoteIdentifier_SQLiteConnection_SQL <- function(conn, x, ...) {
  x
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbQuoteIdentifier", c("SQLiteConnection", "SQL"), dbQuoteIdentifier_SQLiteConnection_SQL)
