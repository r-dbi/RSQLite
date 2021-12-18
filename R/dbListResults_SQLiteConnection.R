#' dbListResults
#'
#' DEPRECATED
#'
#' @keywords internal
#' @usage NULL
dbListResults_SQLiteConnection <- function(conn, ...) {
  warning("Querying the results associated with a connection is no longer supported",
    call. = FALSE
  )
  if (is.null(conn@ref$result)) {
    list()
  } else {
    list(conn@ref$result)
  }
}

#' @export
setMethod("dbListResults", "SQLiteConnection", dbListResults_SQLiteConnection)
