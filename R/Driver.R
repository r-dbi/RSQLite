#' @useDynLib RSQLite
#' @importFrom Rcpp sourceCpp
#' @include Connection.R
NULL

#' Class SQLiteDriver with constructor SQLite (and methods).
#' 
#' \code{SQLite()} returns a SQLiteDriver, which is used to select the correct
#' method in \code{dbConnect()}.
#' 
#' @keywords internal
#' @examples
#' # initialize a new database to a tempfile and copy some data.frame
#' # from the base package into it
#' con <- dbConnect(RSQLite::SQLite(), ":memory:")
#' data(USArrests)
#' dbWriteTable(con, "USArrests", USArrests)
#' 
#' # query
#' rs <- dbSendQuery(con, "select * from USArrests")
#' d1 <- fetch(rs, n = 10)      # extract data in chunks of 10 rows
#' dbHasCompleted(rs)
#' d2 <- fetch(rs, n = -1)      # extract all remaining data
#' dbHasCompleted(rs)
#' dbClearResult(rs)
#' dbListTables(con)
#' 
#' # clean up
#' dbDisconnect(con)
#' @export
setClass("SQLiteDriver", 
  contains = "DBIDriver"
)

#' @rdname SQLiteDriver-class
#' @export
#' @import methods DBI
SQLite <- function(...) {
  if (nargs() > 0) {
    warning("All arguments to RSQLite Driver are ignored.", call. = FALSE)
  }
  new("SQLiteDriver")
}

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
