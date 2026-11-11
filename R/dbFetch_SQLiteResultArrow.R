#' @rdname SQLiteResultArrow-class
#' @inheritParams DBI::dbFetch
#' @usage NULL
dbFetch_SQLiteResultArrow <- function(res, n = -1, ...) {
  dbFetch(res@result, n = n, ...)
}
#' @rdname SQLiteResultArrow-class
#' @export
setMethod("dbFetch", "SQLiteResultArrow", dbFetch_SQLiteResultArrow)
