#' @useDynLib RSQLite
#' @importFrom Rcpp sourceCpp
#' @include Connection.R
NULL

#' Class SQLiteDriver (and methods).
#' 
#' The SQLiteDriver, which is used to select the correct method in 
#' \code{dbConnect()}. See more details in \code{\link{SQLite}}
#' 
#' @keywords internal
#' @export
setClass("SQLiteDriver", 
  contains = "DBIDriver"
)

#' @rdname SQLiteDriver-class
setMethod("show", "SQLiteDriver", function(object) {
  cat("<SQLiteDriver>\n")
})

#' Unload SQLite driver.
#' 
#' This function is no longer needed.
#' 
#' @param drv Object created by \code{\link{SQLite}}
#' @param ... Ignored. Needed for compatibility with generic.
#' @keywords internal
#' @export
setMethod("dbUnloadDriver", "SQLiteDriver", function(drv, ...) {
  invisible(TRUE)
})
