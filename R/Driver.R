#' @include Connection.R
NULL

#' Class SQLiteDriver with constructor SQLite.
#' 
#' An SQLite driver implementing the R/S-Plus database (DBI) API.
#' This class should always be initializes with the \code{SQLite()} function.
#' It returns a singleton object that allows you to connect to the SQLite 
#' engine embedded in R.
#' 
#' This implementation allows the R embedded SQLite engine to work with
#' multiple database instances through multiple connections simultaneously.
#' 
#' SQLite keeps each database instance in one single file. The name of the
#' database \emph{is} the file name, thus database names should be legal file
#' names in the running platform.
#' 
#' @examples
#' # initialize a new database to a tempfile and copy some data.frame
#' # from the base package into it
#' con <- dbConnect(SQLite(), ":memory:")
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

#' @param fetch.default.rec default number of records to fetch at one time from
#'   the database.  The \code{fetch} method will use this number as a default,
#'   but individual calls can override it.
#' @param shared.cache logical describing whether shared-cache mode should be
#'   enabled on the SQLite driver. The default is \code{FALSE}.
#' @param max.con,force.reload Ignored and deprecated.
#' @return An object of class \code{SQLiteDriver} which extends \code{dbDriver}
#'   and \code{dbObjectId}. This object is needed to create connections to the
#'   embedded SQLite database. There can be many SQLite database instances
#'   running simultaneously.
#' 
#' @rdname SQLiteDriver-class
#' @export
#' @import methods DBI
#' @useDynLib RSQLite rsqlite_driver_init
SQLite <- function(max.con = 200L, fetch.default.rec = 500, 
                   force.reload = FALSE, shared.cache = FALSE) {

  if (!missing(max.con)) warning("max.con is ignored", call. = FALSE)
  if (!missing(force.reload)) warning("force.reload is ignored", call. = FALSE)
  
  records <- as.integer(fetch.default.rec)
  cache <- as.logical(shared.cache)
  
  .Call(rsqlite_driver_init, records, cache)
  new("SQLiteDriver")
}

#' Unload SQLite driver.
#' 
#' @param drv Object created by \code{\link{SQLite}}
#' @param ... Ignored. Needed for compatibility with generic.
#' @return A logical indicating whether the operation succeeded or not.
#' @useDynLib RSQLite rsqlite_driver_close
#' @export
#' @examples
#' \dontrun{
#' db <- SQLite()
#' dbUnloadDriver(db)
#' }
setMethod("dbUnloadDriver", "SQLiteDriver", function(drv, ...) {
  .Call(rsqlite_driver_close)  
})
