#' @rdname SQLiteResultArrow-class
#' @inheritParams DBI::dbGetStatement
#' @usage NULL
dbGetStatement_SQLiteResultArrow <- function(res, ...) {
  dbGetStatement(res@result, ...)
}
#' @rdname SQLiteResultArrow-class
#' @export
setMethod("dbGetStatement", "SQLiteResultArrow", dbGetStatement_SQLiteResultArrow)
