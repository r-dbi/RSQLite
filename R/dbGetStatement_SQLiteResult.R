#' @rdname SQLiteResult-class
#' @usage NULL
dbGetStatement_SQLiteResult <- function(res, ...) {
  if (!dbIsValid(res)) {
    stopc("Expired, result set already closed")
  }
  res@sql
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbGetStatement", "SQLiteResult", dbGetStatement_SQLiteResult)
