#' @rdname SQLiteResultArrow-class
#' @inheritParams DBI::dbClearResult
#' @usage NULL
dbClearResult_SQLiteResultArrow <- function(res, ...) {
  dbClearResult(res@result, ...)
}
#' @rdname SQLiteResultArrow-class
#' @export
setMethod("dbClearResult", "SQLiteResultArrow", dbClearResult_SQLiteResultArrow)
