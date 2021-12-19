#' @rdname SQLiteDriver-class
#' @usage NULL
dbUnloadDriver_SQLiteDriver <- function(drv, ...) {
  invisible(TRUE)
}
#' @rdname SQLiteDriver-class
#' @export
setMethod("dbUnloadDriver", "SQLiteDriver", dbUnloadDriver_SQLiteDriver)
