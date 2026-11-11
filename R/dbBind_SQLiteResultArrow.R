#' @rdname SQLiteResultArrow-class
#' @inheritParams DBI::dbBind
#' @usage NULL
dbBind_SQLiteResultArrow <- function(res, params, ...) {
  dbBind(res@result, params, ...)
  invisible(res)
}
#' @rdname SQLiteResultArrow-class
#' @export
setMethod("dbBind", "SQLiteResultArrow", dbBind_SQLiteResultArrow)
