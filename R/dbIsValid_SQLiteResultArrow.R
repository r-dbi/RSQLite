#' @rdname SQLiteResultArrow-class
#' @inheritParams DBI::dbIsValid
#' @usage NULL
dbIsValid_SQLiteResultArrow <- function(dbObj, ...) {
  dbIsValid(dbObj@result, ...)
}
#' @rdname SQLiteResultArrow-class
#' @export
setMethod("dbIsValid", "SQLiteResultArrow", dbIsValid_SQLiteResultArrow)
