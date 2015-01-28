#' Get metadata about a database object.
#' 
#' @param dbObj An object of class \code{\linkS4class{SQLiteDriver}},
#'   \code{\linkS4class{SQLiteConnection}} or 
#'   \code{\linkS4class{SQLiteResult}}
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
setMethod("dbGetInfo", "SQLiteDriver", function(dbObj) {
  list()
})

#' @rdname dbGetInfo
#' @export
#' @useDynLib RSQLite rsqlite_connection_info
setMethod("dbGetInfo", "SQLiteConnection", function(dbObj) {
  check_valid(dbObj)
  info <- .Call(rsqlite_connection_info, dbObj@Id)
  info
})

#' @rdname dbGetInfo
#' @export
#' @useDynLib RSQLite rsqlite_result_info
setMethod("dbGetInfo", "SQLiteResult", function(dbObj) {
  warning("dbGetInfo is deprecated: please use individual metadata functions instead", 
    call. = FALSE)
  
  list()
})
