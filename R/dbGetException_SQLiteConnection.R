# dbWriteTable()
# dbReadTable()
# dbListTables()
# dbExistsTable()
# dbListFields()
# dbRemoveTable()
# dbBegin()
# dbCommit()
# dbRollback()
# other
#' @rdname SQLiteConnection-class
#' @usage NULL
dbGetException_SQLiteConnection <- function(conn, ...) {
  warning_once("RSQLite::dbGetException() is deprecated, please switch to using standard error handling via tryCatch().")
  list(
    errorNum = 0L,
    errorMsg = "OK"
  )
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbGetException", "SQLiteConnection", dbGetException_SQLiteConnection)
