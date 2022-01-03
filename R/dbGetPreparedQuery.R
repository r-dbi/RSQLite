#' @rdname query-dep
#' @export
setGeneric("dbGetPreparedQuery", function(conn, statement, bind.data, ...) {
  standardGeneric("dbGetPreparedQuery")
})
