#' Dummy methods
#'
#' Define here so that these methods can also be imported from this package.
#' Recommended practice is to import all methods from \pkg{DBI}.
#'
#' @name dummy-methods


#' @rdname dummy-methods
#' @aliases dbGetQuery,NULL,ANY-method
#' @inheritParams DBI::dbGetQuery
#' @export
setMethod("dbGetQuery", "NULL", function(conn, statement, ...) {
  stop("conn cannot be NULL", call. = FALSE)
})
