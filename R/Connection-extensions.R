setGeneric("dbSendPreparedQuery", 
  def = function(conn, statement, bind.data, ...) 
    standardGeneric("dbSendPreparedQuery"),
  valueClass = "DBIResult"
)
setGeneric("dbGetPreparedQuery", 
  def = function(conn, statement, bind.data, ...) 
    standardGeneric("dbGetPreparedQuery")
)
setGeneric("dbBeginTransaction", 
  def = function(conn, ...)
    standardGeneric("dbBeginTransaction"),
  valueClass = "logical"
)