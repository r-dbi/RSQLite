#' @rdname SQLiteResultArrow-class
#' @inheritParams DBI::dbHasCompleted
#' @usage NULL
dbHasCompleted_SQLiteResultArrow <- function(res, ...) {
  dbHasCompleted(res@result, ...)
}
#' @rdname SQLiteResultArrow-class
#' @export
setMethod("dbHasCompleted", "SQLiteResultArrow", dbHasCompleted_SQLiteResultArrow)
