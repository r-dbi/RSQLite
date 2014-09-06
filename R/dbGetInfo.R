#' Get metadata about a database object.
#' 
#' @param dbObj,res An object of class \code{\linkS4class{SQLiteDriver}},
#'   \code{\linkS4class{SQLiteConnection}} or 
#'   \code{\linkS4class{SQLiteResult}}
#' @param ... Ignored. Included for compatibility with generic.
#' @name dbGetInfo
#' @examples
#' dbGetInfo(SQLite())
#' 
#' con <- dbConnect(SQLite())
#' dbGetInfo(con)
#' 
#' dbWriteTable(con, "mtcars", mtcars)
#' rs <- dbSendQuery(con, "SELECT * FROM mtcars")
#' dbGetInfo(rs)
#' dbFetch(rs, 1)
#' dbGetInfo(rs)
#' 
#' dbClearResult(rs)
#' dbDisconnect(con)
NULL

#' @rdname dbGetInfo
#' @export
#' @useDynLib RSQLite driverInfo
setMethod("dbGetInfo", "SQLiteDriver", function(dbObj, ...) {
  .Call(driverInfo)
})

#' @rdname dbGetInfo
#' @export
#' @useDynLib RSQLite connectionInfo DBI_newResultHandle
setMethod("dbGetInfo", "SQLiteConnection", function(dbObj, ...) {
  check_valid(dbObj)
  info <- .Call(connectionInfo, dbObj@Id)
  
  if (length(info$rsId) > 0) {
    id <- .Call(DBI_newResultHandle, dbObj@Id, info$rsId)
    info$rsId <- list(new("SQLiteResult", Id = id))
  }
  
  info
})

#' @rdname dbGetInfo
#' @export
#' @useDynLib RSQLite resultSetInfo RS_DBI_SclassNames typeNames
setMethod("dbGetInfo", "SQLiteResult", function(dbObj, ...) {
  check_valid(dbObj)
  
  info <- .Call(resultSetInfo, dbObj@Id)
  flds <- info$fieldDescription[[1]]
  
  if (is.null(flds)) return(info)
  
  flds$Sclass <- .Call(RS_DBI_SclassNames, flds$Sclass)
  flds$type <- .Call(typeNames, flds$type)

  info$fields <- structure(flds, 
    row.names = .set_row_names(length(flds[[1]])),
    class = "data.frame"
  )
  info$fieldDescription <- NULL
  
  info
})
