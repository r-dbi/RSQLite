#' @rdname sqlite-transaction
#' @usage NULL
dbRollback_SQLiteConnection <- function(conn, .name = NULL, ..., name = NULL) {
  name <- compat_name(name, .name)
  if (is.null(name)) {
    dbExecute(conn, "ROLLBACK")
  } else {
    # The ROLLBACK TO command reverts the state of the database back to what it
    # was just after the corresponding SAVEPOINT. Note that unlike that plain
    # ROLLBACK command (without the TO keyword) the ROLLBACK TO command does not
    # cancel the transaction. Instead of cancelling the transaction, the
    # ROLLBACK TO command restarts the transaction again at the beginning. All
    # intervening SAVEPOINTs are canceled, however.
    name_quoted <- dbQuoteIdentifier(conn, name)
    dbExecute(conn, paste0("ROLLBACK TO ", name_quoted))
    dbExecute(conn, paste0("RELEASE SAVEPOINT ", name_quoted))
  }
  connection_rem_transaction(conn@ptr)
  invisible(TRUE)
}
#' @rdname sqlite-transaction
#' @export
setMethod("dbRollback", "SQLiteConnection", dbRollback_SQLiteConnection)
