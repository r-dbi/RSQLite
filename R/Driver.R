#' @include Object.R
NULL

setClass("SQLiteDriver", representation("DBIDriver", "SQLiteObject"))

SQLite <-
  function(max.con = 200L, fetch.default.rec = 500, force.reload = FALSE,
    shared.cache=FALSE)
  {
    sqliteInitDriver(max.con, fetch.default.rec, force.reload, shared.cache)
  }

## return a manager id
sqliteInitDriver <- function(max.con = 16, fetch.default.rec = 500, 
                             force.reload=FALSE, shared.cache=FALSE) {
  config.params <- as.integer(c(max.con, fetch.default.rec))
  force <- as.logical(force.reload)
  cache <- as.logical(shared.cache)
  id <- .Call("RS_SQLite_init", config.params, force, cache, PACKAGE = .SQLitePkgName)
  new("SQLiteDriver", Id = id)
}

setMethod("dbUnloadDriver", "SQLiteDriver",
  definition = function(drv, ...) sqliteCloseDriver(drv, ...),
  valueClass = "logical"
)
sqliteCloseDriver <- function(drv, ...) {
  .Call("RS_SQLite_closeManager", drv@Id, PACKAGE = .SQLitePkgName)
}


setMethod("dbGetInfo", "SQLiteDriver",
  definition = function(dbObj, ...) sqliteDriverInfo(dbObj, ...),
  valueClass = "list"
)
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


setMethod("dbListConnections", "SQLiteDriver",
  definition = function(drv, ...) {
    cons <- dbGetInfo(drv, what = "connectionIds")[[1]]
    if(!is.null(cons)) cons else list()
  },
  valueClass = "list"
)

setMethod("summary", "SQLiteDriver",
  definition = function(object, ...) sqliteDescribeDriver(object, ...)
)

## Print out nicely a brief description of the connection Manager
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