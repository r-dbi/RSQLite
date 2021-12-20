#' @rdname SQLiteResult-class
#' @usage NULL
dbClearResult_SQLiteResult <- function(res, ...) {
  if (!dbIsValid(res)) {
    warningc("Expired, result set already closed")
    return(invisible(TRUE))
  }
  result_release(res@ptr)
  res@conn@ref$result <- NULL
  invisible(TRUE)
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbClearResult", "SQLiteResult", dbClearResult_SQLiteResult)
