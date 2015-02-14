#' Get metadata about a database object.
#' 
#' Deprecated. Please use individual functions.
#' 
#' @param dbObj An object of class \code{\linkS4class{SQLiteDriver}},
#'   \code{\linkS4class{SQLiteConnection}} or 
#'   \code{\linkS4class{SQLiteResult}}
#' @name dbGetInfo
#' @keywords internal
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
