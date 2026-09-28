#' @rdname SQLiteResultArrow-class
#' @usage NULL
dbFetchArrowChunk_SQLiteResultArrow <- function(res, ..., chunk_size = 65536L) {
  dbFetchArrowChunk(res@result, ..., chunk_size = chunk_size)
}
#' @rdname SQLiteResultArrow-class
#' @export
setMethod("dbFetchArrowChunk", "SQLiteResultArrow", dbFetchArrowChunk_SQLiteResultArrow)
