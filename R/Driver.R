#' @include Connection.R
#' @include Object.R
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
setClass("SQLiteDriver", representation("DBIDriver", "SQLiteObject"))

setAs("SQLiteConnection", "SQLiteDriver",
  def = function(from) new("SQLiteDriver", Id = from@Id)
)

#' @param max.con IGNORED.  As of RSQLite 0.9.0, connections are managed
#'   dynamically and there is no predefined limit to the number of connections
#'   you can have in a given R session.
#' @param fetch.default.rec default number of records to fetch at one time from
#'   the database.  The \code{fetch} method will use this number as a default,
#'   but individual calls can override it.
#' @param force.reload should the package code be reloaded (reinitialized)?
#'   Setting this to \code{TRUE} allows you to change default settings.  Notice
#'   that all connections should be closed before re-loading.
#' @param shared.cache logical describing whether shared-cache mode should be
#'   enabled on the SQLite driver. The default is \code{FALSE}.
#' @return An object of class \code{SQLiteDriver} which extends \code{dbDriver}
#'   and \code{dbObjectId}. This object is needed to create connections to the
#'   embedded SQLite database. There can be many SQLite database instances
#'   running simultaneously.
#' 
#' @rdname SQLiteDriver-class
#' @export
#' @useDynLib RSQLite RS_SQLite_init
SQLite <- function(max.con = 200L, fetch.default.rec = 500, 
                   force.reload = FALSE, shared.cache = FALSE) {

  config.params <- as.integer(c(max.con, fetch.default.rec))
  force <- as.logical(force.reload)
  cache <- as.logical(shared.cache)
  
  id <- .Call(RS_SQLite_init, config.params, force, cache)
  new("SQLiteDriver", Id = id)
}

#' Unload SQLite driver.
#' 
#' @param drv Object created by \code{\link{SQLite}}
#' @param ... Ignored. Needed for compatibility with generic.
#' @return A logical indicating whether the operation succeeded or not.
#' @useDynLib RSQLite RS_SQLite_closeManager
#' @export
#' @examples
#' \dontrun{
#' db <- SQLite()
#' dbUnloadDriver(db)
#' }
setMethod("dbUnloadDriver", "SQLiteDriver", function(drv, ...) {
  .Call(RS_SQLite_closeManager, drv@Id)  
})

#' List active connections
#' 
#' @param drv An object of class \code{\linkS4class{SQLiteDriver}}
#' @param ... Ignored. Needed for compatibility with generic.
#' @export
setMethod("dbListConnections", "SQLiteDriver", function(drv, ...) {
  cons <- dbGetInfo(drv, what = "connectionIds")[[1]]
  if(!is.null(cons)) cons else list()
})

