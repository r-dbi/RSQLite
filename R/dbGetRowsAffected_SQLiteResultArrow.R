#' @rdname SQLiteResultArrow-class
#' @inheritParams DBI::dbGetRowsAffected
#' @usage NULL
dbGetRowsAffected_SQLiteResultArrow <- function(res, ...) {
  dbGetRowsAffected(res@result, ...)
}
#' @rdname SQLiteResultArrow-class
#' @export
setMethod("dbGetRowsAffected", "SQLiteResultArrow", dbGetRowsAffected_SQLiteResultArrow)
