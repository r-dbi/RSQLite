#' @rdname sqlite-transaction
#' @usage NULL
dbBegin_SQLiteConnection <- function(conn, .name = NULL, ..., name = NULL) {
  name <- compat_name(name, .name)
  if (is.null(name)) {
    dbExecute(conn, "BEGIN")
  } else {
    dbExecute(conn, paste0("SAVEPOINT ", dbQuoteIdentifier(conn, name)))
  }
  connection_add_transaction(conn@ptr)
  invisible(TRUE)
}
#' @rdname sqlite-transaction
#' @export
setMethod("dbBegin", "SQLiteConnection", dbBegin_SQLiteConnection)
