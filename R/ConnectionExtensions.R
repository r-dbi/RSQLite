#' @export
setGeneric("dbSendPreparedQuery", 
  def = function(conn, statement, bind.data, ...) 
    standardGeneric("dbSendPreparedQuery"),
  valueClass = "DBIResult"
)

#' @export
setGeneric("dbGetPreparedQuery", 
  def = function(conn, statement, bind.data, ...) 
    standardGeneric("dbGetPreparedQuery")
)

#' @export
setGeneric("dbBeginTransaction", 
  def = function(conn, ...)
    standardGeneric("dbBeginTransaction"),
  valueClass = "logical"
)