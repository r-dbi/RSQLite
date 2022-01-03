#' @rdname SQLiteResult-class
#' @usage NULL
dbGetRowCount_SQLiteResult <- function(res, ...) {
  result_rows_fetched(res@ptr)
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbGetRowCount", "SQLiteResult", dbGetRowCount_SQLiteResult)
