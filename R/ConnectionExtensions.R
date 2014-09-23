#' Generics for getting and sending prepared queries.
#' 
#' @param conn An \code{DBIConnection} object.
#' @param statement A SQL string
#' @param bind.data A data frame
#' @param ... Other arguments used by methods
#' @export
setGeneric("dbSendPreparedQuery", function(conn, statement, bind.data, ...) {
  standardGeneric("dbSendPreparedQuery")
})

#' @rdname dbSendPreparedQuery
#' @export
setGeneric("dbGetPreparedQuery", function(conn, statement, bind.data, ...) {
  standardGeneric("dbGetPreparedQuery")
})

#' Generic for creating a new transaction.
#' 
#' See method documentation for details.
#' 
#' @export
#' @param conn An \code{DBIConnection} object.
#' @param ... Other arguments used by methods
#' @keywords internal
setGeneric("dbBeginTransaction", function(conn, ...) {
  .Deprecated("dbBegin")
  dbBegin(conn, ...)
})