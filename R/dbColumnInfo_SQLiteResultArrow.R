#' @rdname SQLiteResultArrow-class
#' @inheritParams DBI::dbColumnInfo
#' @usage NULL
dbColumnInfo_SQLiteResultArrow <- function(res, ...) {
  dbColumnInfo(res@result, ...)
}
#' @rdname SQLiteResultArrow-class
#' @export
setMethod("dbColumnInfo", "SQLiteResultArrow", dbColumnInfo_SQLiteResultArrow)
