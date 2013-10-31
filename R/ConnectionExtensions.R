#' Generics for getting and sending prepared queries.
#' 
#' @param conn An \code{DBIConnection} object.
#' @param statement A SQL string
#' @param bind.data A data frame
#' @param ... Other arguments used by methods
#' @export
setGeneric("dbSendPreparedQuery", 
  def = function(conn, statement, bind.data, ...) 
    standardGeneric("dbSendPreparedQuery"),
  valueClass = "DBIResult"
)

#' @rdname dbSendPreparedQuery
#' @export
setGeneric("dbGetPreparedQuery", 
  def = function(conn, statement, bind.data, ...) 
    standardGeneric("dbGetPreparedQuery")
)

#' Generic for creating a new transaction.
#' 
#' See method documentation for details.
#' 
#' @export
#' @param conn An \code{DBIConnection} object.
#' @param ... Other arguments used by methods
setGeneric("dbBeginTransaction", 
  def = function(conn, ...)
    standardGeneric("dbBeginTransaction"),
  valueClass = "logical"
)