#' @rdname SQLiteResult-class
#' @usage NULL
dbIsValid_SQLiteResult <- function(dbObj, ...) {
  result_valid(dbObj@ptr)
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbIsValid", "SQLiteResult", dbIsValid_SQLiteResult)
