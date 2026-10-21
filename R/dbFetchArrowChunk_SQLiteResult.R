#' @rdname SQLiteResult-class
#' @usage NULL
dbFetchArrowChunk_SQLiteResult <- function(res, ..., chunk_size = 65536L) {
  chunk_size <- check_chunk_size(chunk_size)
  result_fetch_arrow_chunk(res@ptr, chunk_size)
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbFetchArrowChunk", "SQLiteResult", dbFetchArrowChunk_SQLiteResult)
