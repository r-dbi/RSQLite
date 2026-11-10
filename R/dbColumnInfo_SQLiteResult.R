#' @rdname SQLiteResult-class
#' @usage NULL
dbColumnInfo_SQLiteResult <- function(res, ...) {
  if (res@conn@arrow) {
    return(arrow_column_info(res))
  }
  df <- result_column_info(res@ptr)
  df
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbColumnInfo", "SQLiteResult", dbColumnInfo_SQLiteResult)
