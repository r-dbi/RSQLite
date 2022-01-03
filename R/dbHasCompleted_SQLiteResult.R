#' @rdname SQLiteResult-class
#' @usage NULL
dbHasCompleted_SQLiteResult <- function(res, ...) {
  result_has_completed(res@ptr)
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbHasCompleted", "SQLiteResult", dbHasCompleted_SQLiteResult)
