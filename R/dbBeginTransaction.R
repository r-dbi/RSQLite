#' Generic for creating a new transaction
#'
#' See method documentation for details.
#'
#' @export
#' @param conn A `DBIConnection` object.
#' @param ... Other arguments used by methods
#' @keywords internal
setGeneric("dbBeginTransaction", function(conn, ...) {
  .Deprecated("dbBegin", old = "dbBeginTransaction")
  dbBegin(conn, ...)
})
