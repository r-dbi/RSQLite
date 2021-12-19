#' @rdname SQLite
#' @usage NULL
dbDisconnect_SQLiteConnection <- function(conn, ...) {
  connection_release(conn@ptr)
  invisible(TRUE)
}
#' @rdname SQLite
#' @export
setMethod("dbDisconnect", "SQLiteConnection", dbDisconnect_SQLiteConnection)
