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
#' @useDynLib RSQLite RS_SQLite_managerInfo
setMethod("dbGetInfo", "SQLiteDriver", function(dbObj, ...) {
  check_valid(dbObj)  
  .Call(RS_SQLite_managerInfo, dbObj@Id)
})

#' @rdname dbGetInfo
#' @export
#' @useDynLib RSQLite RSQLite_connectionInfo DBI_newResultHandle
setMethod("dbGetInfo", "SQLiteConnection", function(dbObj, ...) {
  check_valid(dbObj)
  info <- .Call(RSQLite_connectionInfo, dbObj@Id)
  
  if (length(info$rsId) > 0) {
    id <- .Call(DBI_newResultHandle, dbObj@Id, info$rsId)
    info$rsId <- list(new("SQLiteResult", Id = id))
  }
  
  info
})

#' @rdname dbGetInfo
#' @export
#' @useDynLib RSQLite RS_SQLite_resultSetInfo RS_DBI_SclassNames RS_SQLite_typeNames
setMethod("dbGetInfo", "SQLiteResult", function(dbObj, ...) {
  check_valid(dbObj)
  
  info <- .Call(RS_SQLite_resultSetInfo, dbObj@Id)
  flds <- info$fieldDescription[[1]]
  if (is.null(flds)) return(info)
  
  flds$Sclass <- .Call(RS_DBI_SclassNames, flds$Sclass)
  flds$type <- .Call(RS_SQLite_typeNames, flds$type)

  info$fields <- structure(flds, 
    row.names = .set_row_names(length(flds[[1]])),
    class = "data.frame"
  )
  info$fieldDescription <- NULL
  
  info
})

#' @rdname dbGetInfo
#' @export
setMethod("dbGetStatement", "SQLiteResult", function(res, ...) {
  dbGetInfo(res, "statement")[[1]]
})
