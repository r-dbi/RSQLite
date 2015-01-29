#' Deprecated querying tools
#' 
#' These functions have been deprecated. Please switch to using 
#' \code{dbSendQuery}/\code{dbGetQuery} + \code{dbBind} instead.
#' 
#' @keywords internal
#' @name query-dep
NULL

#' @rdname query-dep
#' @param bind.data A data frame of data to be bound.
#' @export
setMethod("dbSendPreparedQuery", 
  c("SQLiteConnection", "character", "data.frame"),
  function(conn, statement, bind.data) {
    stop("Please use dbSendQuery instead", call. = FALSE)
  }
)

#' @rdname query-dep
#' @export
setMethod("dbGetPreparedQuery", 
  c("SQLiteConnection", "character", "data.frame"),
  function(conn, statement, bind.data) {
    stop("Please use dbGetQuery instead", call. = FALSE)
  }
)
