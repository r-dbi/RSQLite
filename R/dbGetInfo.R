#' Get metadata about a database object.
#' 
#' @param dbObj,res An object of class \code{\linkS4class{SQLiteDriver}},
#'   \code{\linkS4class{SQLiteConnection}} or 
#'   \code{\linkS4class{SQLiteResult}}
#' @param ... Ignored. Included for compatibility with generic.
#' @name dbGetInfo
NULL

#' @rdname dbGetInfo
#' @export
setMethod("dbGetInfo", "SQLiteDriver", function(dbObj, ...) {
  sqliteDriverInfo(dbObj, ...)
})

#' @useDynLib RSQLite RS_SQLite_managerInfo
sqliteDriverInfo <- function(obj, what="", ...) {
  if(!isIdCurrent(obj))
    stop(paste("expired", class(obj)))
  drvId <- obj@Id
  info <- .Call(RS_SQLite_managerInfo, drvId)
  info$managerId <- obj
  ## connection IDs are no longer tracked by the manager.
  info$connectionIds <- list()
  if(!missing(what))
    info[what]
  else
    info
}

#' @rdname dbGetInfo
#' @export
setMethod("dbGetInfo", "SQLiteConnection", function(dbObj, ...) {
  sqliteConnectionInfo(dbObj, ...)
})

#' @useDynLib RSQLite RSQLite_connectionInfo DBI_newResultHandle
sqliteConnectionInfo <- function(obj, what="", ...) {
  if(!isIdCurrent(obj))
    stop(paste("expired", class(obj)))
  id <- obj@Id
  info <- .Call(RSQLite_connectionInfo, id)
  if(length(info$rsId)){
    rsId <- vector("list", length = length(info$rsId))
    for(i in seq(along.with = info$rsId))
      rsId[[i]] <- new("SQLiteResult",
        Id = .Call(DBI_newResultHandle, id, info$rsId[i]))
    info$rsId <- rsId
  }
  if(!missing(what))
    info[what]
  else
    info
}

#' @rdname dbGetInfo
#' @export
setMethod("dbGetInfo", "SQLiteResult", function(dbObj, ...) {
  sqliteResultInfo(dbObj, ...)
})

#' @rdname dbGetInfo
#' @export
setMethod("dbGetStatement", "SQLiteResult", function(res, ...) {
  dbGetInfo(res, "statement")[[1]]
})
