# dbIsValid()
#' @rdname SQLiteConnection-class
#' @usage NULL
dbIsValid_SQLiteConnection <- function(dbObj, ...) {
  connection_valid(dbObj@ptr)
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbIsValid", "SQLiteConnection", dbIsValid_SQLiteConnection)
