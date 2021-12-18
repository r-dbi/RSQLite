#' Fetch
#'
#' A shortcut for \code{\link[DBI]{dbFetch}(res, n = n, row.names = FALSE)},
#' kept for compatibility reasons.
#'
#' @keywords internal
#' @usage NULL
fetch_SQLiteResult <- function(res, n = -1, ...) {
  dbFetch(res, n = n, row.names = FALSE)
}

#' @export
setMethod("fetch", "SQLiteResult", fetch_SQLiteResult)
