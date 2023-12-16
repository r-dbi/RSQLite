#' @rdname SQLiteResult-class
#' @usage NULL
dbGetRowsAffected_SQLiteResult <- function(res, ...) {
  out <- result_rows_affected(res@ptr)
  if (out > 0) {
    out <- NA_integer_
  }
  out
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbGetRowsAffected", "SQLiteResult", dbGetRowsAffected_SQLiteResult)
