#' @rdname sqlite-transaction
#' @usage NULL
dbCommit_SQLiteConnection <- function(conn, .name = NULL, ..., name = NULL) {
  name <- compat_name(name, .name)
  if (is.null(name)) {
    dbExecute(conn, "COMMIT")
  } else {
    dbExecute(conn, paste0("RELEASE SAVEPOINT ", dbQuoteIdentifier(conn, name)))
  }
  invisible(TRUE)
}
#' @rdname sqlite-transaction
#' @export
setMethod("dbCommit", "SQLiteConnection", dbCommit_SQLiteConnection)
