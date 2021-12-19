#' @rdname SQLiteResult-class
#' @usage NULL
dbGetRowsAffected_SQLiteResult <- function(res, ...) {
  result_rows_affected(res@ptr)
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbGetRowsAffected", "SQLiteResult", dbGetRowsAffected_SQLiteResult)
