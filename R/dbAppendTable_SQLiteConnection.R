#' @rdname SQLiteConnection-class
#' @usage NULL
dbAppendTable_SQLiteConnection <- function(conn, name, value, ...,
                                           row.names = NULL) {
  savepoint_id <- get_savepoint_id("dbAppendTable")
  dbBegin(conn, name = savepoint_id)
  on.exit(dbRollback(conn, name = savepoint_id))

  if (conn@arrow) {
    if (!is.null(row.names)) {
      stopc("Can't pass `row.names` to `dbAppendTable()`")
    }
    stopifnot(is.data.frame(value))
    out <- arrow_append_df(conn, name, value)
  } else {
    out <- callNextMethod()
  }

  on.exit(NULL)
  dbCommit(conn, name = savepoint_id)

  out
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbAppendTable", "SQLiteConnection", dbAppendTable_SQLiteConnection)
