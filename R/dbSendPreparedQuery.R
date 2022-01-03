#' @rdname query-dep
#'
#' @param conn A `DBIConnection` object.
#' @param statement A SQL string
#' @param bind.data A data frame
#' @param ... Other arguments used by methods
#' @export
setGeneric("dbSendPreparedQuery", function(conn, statement, bind.data, ...) {
  standardGeneric("dbSendPreparedQuery")
})
