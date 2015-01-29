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
setMethod("dbGetInfo", "SQLiteConnection", function(dbObj) {
  warning("dbGetInfo is deprecated: please use individual metadata functions instead", 
    call. = FALSE)
  
  list()
})

#' @rdname dbGetInfo
#' @export
setMethod("dbGetInfo", "SQLiteResult", function(dbObj) {
  warning("dbGetInfo is deprecated: please use individual metadata functions instead", 
    call. = FALSE)
  
  list()
})
