#' Fetch
#'
#' A shortcut for \code{\link[DBI]{dbFetch}(res, n = n, row.names = FALSE)},
#' kept for compatibility reasons.
#'
#' @rdname fetch
#' @keywords internal
#' @usage NULL
fetch_SQLiteResult <- function(res, n = -1, ...) {
  dbFetch(res, n = n, row.names = FALSE)
}

#' @rdname fetch
#' @export
setMethod("fetch", "SQLiteResult", fetch_SQLiteResult)
