#' @rdname SQLiteResultArrow-class
#' @inheritParams DBI::dbBindArrow
#' @usage NULL
dbBindArrow_SQLiteResultArrow <- function(res, params, ...) {
  dbBindArrow(res@result, params, ...)
  invisible(res)
}
#' @rdname SQLiteResultArrow-class
#' @export
setMethod("dbBindArrow", "SQLiteResultArrow", dbBindArrow_SQLiteResultArrow)
