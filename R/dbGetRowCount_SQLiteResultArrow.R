#' @rdname SQLiteResultArrow-class
#' @inheritParams DBI::dbGetRowCount
#' @usage NULL
dbGetRowCount_SQLiteResultArrow <- function(res, ...) {
  dbGetRowCount(res@result, ...)
}
#' @rdname SQLiteResultArrow-class
#' @export
setMethod("dbGetRowCount", "SQLiteResultArrow", dbGetRowCount_SQLiteResultArrow)
