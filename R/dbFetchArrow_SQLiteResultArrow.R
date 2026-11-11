#' @rdname SQLiteResultArrow-class
#' @inheritParams DBI::dbFetchArrow
#' @param chunk_size The number of rows in each Arrow array of the stream returned by `dbFetchArrow()`,
#'   or in the array returned by `dbFetchArrowChunk()`, see [sqlite-arrow].
#' @usage NULL
dbFetchArrow_SQLiteResultArrow <- function(res, ..., chunk_size = 65536L) {
  dbFetchArrow(res@result, ..., chunk_size = chunk_size)
}
#' @rdname SQLiteResultArrow-class
#' @export
setMethod("dbFetchArrow", "SQLiteResultArrow", dbFetchArrow_SQLiteResultArrow)
