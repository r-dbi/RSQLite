#' @rdname SQLiteResult-class
#' @usage NULL
dbFetchArrowChunk_SQLiteResult <- function(res, ..., chunk_size = 65536L) {
  chunk_size <- check_chunk_size(chunk_size)
  chunk <- result_fetch_arrow_chunk(res@ptr, chunk_size)
  arrow_chunk_handed_out(chunk$bytes)
  chunk$array
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbFetchArrowChunk", "SQLiteResult", dbFetchArrowChunk_SQLiteResult)
