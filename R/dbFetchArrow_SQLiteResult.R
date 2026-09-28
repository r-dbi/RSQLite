#' @rdname SQLiteResult-class
#' @param chunk_size The number of rows in each Arrow array of the stream returned by `dbFetchArrow()`,
#'   or in the array returned by `dbFetchArrowChunk()`, see [sqlite-arrow].
#' @usage NULL
dbFetchArrow_SQLiteResult <- function(res, ..., chunk_size = 65536L) {
  chunk_size <- check_chunk_size(chunk_size)
  result_fetch_arrow(res@ptr, chunk_size)
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbFetchArrow", "SQLiteResult", dbFetchArrow_SQLiteResult)
