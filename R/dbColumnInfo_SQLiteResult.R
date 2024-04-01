#' @rdname SQLiteResult-class
#' @usage NULL
dbColumnInfo_SQLiteResult <- function(res, ...) {
  df <- result_column_info(res@ptr)
  df
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbColumnInfo", "SQLiteResult", dbColumnInfo_SQLiteResult)
