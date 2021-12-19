#' @rdname SQLiteDriver-class
#' @usage NULL
dbIsValid_SQLiteDriver <- function(dbObj, ...) {
  TRUE
}
#' @rdname SQLiteDriver-class
#' @export
setMethod("dbIsValid", "SQLiteDriver", dbIsValid_SQLiteDriver)
