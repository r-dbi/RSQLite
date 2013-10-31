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
#' @name SQLiteDriver-class
#' @docType class
#'
#' @examples
#' # create a SQLite instance and create one connection.
#' m <- dbDriver(SQLite())
#' 
#' # initialize a new database to a tempfile and copy some data.frame
#' # from the base package into it
#' tfile <- tempfile()
#' con <- dbConnect(m, dbname = tfile)
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
#' file.info(tfile)
#' file.remove(tfile)
#' @export
setClass("SQLiteDriver", representation("DBIDriver", "SQLiteObject"))

#' @param max.con IGNORED.  As of RSQLite 0.9.0, connections are managed
#' dynamically and there is no predefined limit to the number of connections
#' you can have in a given R session.
#' @param fetch.default.rec default number of records to fetch at one time from
#' the database.  The \code{fetch} method will use this number as a default,
#' but individual calls can override it.
#' @param force.reload should the package code be reloaded (reinitialized)?
#' Setting this to \code{TRUE} allows you to change default settings.  Notice
#' that all connections should be closed before re-loading.
#' @param shared.cache logical describing whether shared-cache mode should be
#' enabled on the SQLite driver. The default is \code{FALSE}.
#' @return An object of class \code{SQLiteDriver} which extends \code{dbDriver}
#' and \code{dbObjectId}. This object is needed to create connections to the
#' embedded SQLite database. There can be many SQLite database instances
#' running simultaneously.
#' 
#' @rdname SQLiteDriver-class
#' @export
SQLite <- function(max.con = 200L, fetch.default.rec = 500, 
                   force.reload = FALSE, shared.cache=FALSE) {
  sqliteInitDriver(max.con, fetch.default.rec, force.reload, shared.cache)
}

#' @rdname SQLiteDriver-class
#' @export
sqliteInitDriver <- function(max.con = 16, fetch.default.rec = 500, 
                             force.reload=FALSE, shared.cache=FALSE) {
  config.params <- as.integer(c(max.con, fetch.default.rec))
  force <- as.logical(force.reload)
  cache <- as.logical(shared.cache)
  id <- .Call("RS_SQLite_init", config.params, force, cache, PACKAGE = .SQLitePkgName)
  new("SQLiteDriver", Id = id)
}

#' @export
#' @rdname SQLiteDriver-class
setMethod("summary", "SQLiteDriver",
  definition = function(object, ...) sqliteDescribeDriver(object, ...)
)

#' @export
#' @rdname SQLiteDriver-class
sqliteDescribeDriver <- function(obj, verbose = FALSE, ...) {
  if(!isIdCurrent(obj)){
    show(obj)
    invisible(return(NULL))
  }
  info <- dbGetInfo(obj)
  show(obj)
  cat("  Driver name: ", info$drvName, "\n")
  cat("  Max  connections:", info$length, "\n")
  cat("  Conn. processed:", info$counter, "\n")
  cat("  Default records per fetch:", info$"fetch_default_rec", "\n")
  if(verbose){
    cat("  SQLite client version: ", info$clientVersion, "\n")
    cat("  DBI version: ", dbGetDBIVersion(), "\n")
  }
  cat("  Open connections:", info$"num_con", "\n")
  if(verbose && !is.null(info$connectionIds)){
    for(i in seq(along.with = info$connectionIds)){
      cat("   ", i, " ")
      show(info$connectionIds[[i]])
    }
  }
  cat("  Shared Cache:", info$"shared_cache", "\n")
  invisible(NULL)
}


#' Unload SQLite driver.
#' 
#' @param drv Object created by \code{\link{SQLite}}
#' @param ... Ignored. Needed for compatibility with generic.
#' @return A logical indicating whether the operation succeeded or not.
#' @export
setMethod("dbUnloadDriver", "SQLiteDriver",
  definition = function(drv, ...) sqliteCloseDriver(drv, ...),
  valueClass = "logical"
)
#' @export
#' @rdname dbUnloadDriver-SQLiteDriver-method
sqliteCloseDriver <- function(drv, ...) {
  .Call("RS_SQLite_closeManager", drv@Id, PACKAGE = .SQLitePkgName)
}


#' @export
setMethod("dbGetInfo", "SQLiteDriver",
  definition = function(dbObj, ...) sqliteDriverInfo(dbObj, ...),
  valueClass = "list"
)
#' @export
sqliteDriverInfo <- function(obj, what="", ...) {
  if(!isIdCurrent(obj))
    stop(paste("expired", class(obj)))
  drvId <- obj@Id
  info <- .Call("RS_SQLite_managerInfo", drvId, PACKAGE = .SQLitePkgName)
  info$managerId <- obj
  ## connection IDs are no longer tracked by the manager.
  info$connectionIds <- list()
  if(!missing(what))
    info[what]
  else
    info
}

#' @export
setMethod("dbListConnections", "SQLiteDriver",
  definition = function(drv, ...) {
    cons <- dbGetInfo(drv, what = "connectionIds")[[1]]
    if(!is.null(cons)) cons else list()
  },
  valueClass = "list"
)


#' Create an SQLite connection.
#' 
#' @param drv An objected generated by \code{\link{SQLite()}}, or an existing
#'   \code{\linkS4class{SQLiteConnection}}. If an connection, the connection
#'   will be cloned.
#' @param dbname A path to a SQLite database. If the path does not exist,
#'   it will be created an initialied with an empty database.
#' @param conn an \code{SQLiteConnection} object as produced by 
#'  \code{dbConnect}.
#' @param ... Arguments passed on to \code{sqliteNewConnection}
#' @param cache_size a positive integer to change the maximum number of
#'   disk pages that SQLite holds in memory (SQLite's default is 2000 pages).
#' @param synchronous Possible values for \code{synchronous} are
#'   0 (the default), 1, or 2 or the corresponding strings "OFF", "NORMAL", or 
#'   "FULL".  Users have reported significant speed ups using 
#'   \code{sychronous=0}, and the SQLite documentation itself implies 
#'   considerable improved performance at the very modest risk of database 
#'   corruption in the unlikely case of the operating system (\emph{not} the 
#'   R application) crashing. See the SQLite documentation for the full details 
#'   of this \code{PRAGMA}.
#' @export
setMethod("dbConnect", "SQLiteDriver",
  definition = function(drv, ...) sqliteNewConnection(drv, ...),
  valueClass = "SQLiteConnection"
)

#' @export
#' @rdname dbConnect-SQLiteDriver-method
setMethod("dbConnect", "character",
  definition = function(drv, ...){
    d <- dbDriver(drv)
    dbConnect(d, ...)
  },
  valueClass = "SQLiteConnection"
)

#' @export
#' @rdname dbConnect-SQLiteDriver-method
setMethod("dbConnect", "SQLiteConnection",
  definition = function(drv, ...){
    new.id <- .Call("RS_SQLite_cloneConnection", drv@Id, PACKAGE = .SQLitePkgName)
    new("SQLiteConnection", Id = new.id)
  },
  valueClass = "SQLiteConnection"
)

#' @export
#' @rdname dbConnect-SQLiteDriver-method
#' @param flags \code{SQLITE_RWC}: open the database in read/write mode
#'   and create the database file if it does not already exist; 
#'   \code{SQLITE_RW}: open the database in read/write mode. Raise an error 
#'   if the file does not already exist; \code{SQLITE_RO}: open the database in 
#'   read only mode.  Raise an error if the file does not already exist
#' @aliases SQLITE_RWC SQLITE_RW SQLITE_RO
sqliteNewConnection <- function(drv, dbname = "", loadable.extensions = TRUE,
                                cache_size = NULL, synchronous = 0, flags = NULL, 
                                vfs = NULL) {
  if (is.null(dbname))
    dbname <- ""
  ## path.expand converts as.character(NA) => "NA"
  if (any(is.na(dbname)))
    stop("'dbname' must not be NA")
  dbname <- path.expand(dbname)
  loadable.extensions <- as.logical(loadable.extensions)
  if (!is.null(vfs)) {
    if (.Platform[["OS.type"]] == "windows") {
      warning("vfs customization not available on this platform.",
        " Ignoring value: vfs = ", vfs)
    } else {
      if (length(vfs) != 1L)
        stop("'vfs' must be NULL or a character vector of length one")
      allowed <- c("unix-posix", "unix-afp", "unix-flock", "unix-dotfile",
        "unix-none")
      if (!(vfs %in% allowed)) {
        stop("'vfs' must be one of ",
          paste(allowed, collapse=", "),
          ". See http://www.sqlite.org/compile.html")
      }
    }
  }
  flags <- if (is.null(flags)) SQLITE_RWC else flags
  drvId <- drv@Id
  conId <- .Call("RS_SQLite_newConnection", drvId,
    dbname, loadable.extensions, flags, vfs, PACKAGE ="RSQLite")
  con <- new("SQLiteConnection", Id = conId)
  
  ## experimental PRAGMAs
  try({
    if(!is.null(cache_size))
      dbGetQuery(con, sprintf("PRAGMA cache_size=%d", as.integer(cache_size)))
    if(is.numeric(synchronous))
      nsync <- as.integer(synchronous)
    else if(is.character(synchronous))
      nsync <-
      pmatch(tolower(synchronous), c("off", "normal", "full"), nomatch = 1) - 1
    else nsync <- 0
    dbGetQuery(con, sprintf("PRAGMA synchronous=%d", as.integer(nsync)))
  }, silent = TRUE)
  
  con
}
