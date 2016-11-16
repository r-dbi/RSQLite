#' @useDynLib RSQLite
#' @importFrom Rcpp sourceCpp
NULL

#' Class SQLiteDriver (and methods)
#'
#' The SQLiteDriver, which is used to select the correct method in
#' [dbConnect()]. See more details in [SQLite()].
#' It is used purely for dispatch and [dbUnloadDriver()] is a null-op.
#'
#' @keywords internal
#' @export
setClass("SQLiteDriver",
  contains = "DBIDriver"
)

#' @rdname SQLiteDriver-class
#' @export
setMethod("dbIsValid", "SQLiteDriver", function(dbObj, ...) {
  TRUE
})

#' @rdname SQLiteDriver-class
#' @export
setMethod("dbUnloadDriver", "SQLiteDriver", function(drv, ...) {
  invisible(TRUE)
})
