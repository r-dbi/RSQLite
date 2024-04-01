#' @rdname SQLiteResult-class
#' @usage NULL
dbFetch_SQLiteResult <- function(res, n = -1, ...,
                                 row.names = pkgconfig::get_config("RSQLite::row.names.query", FALSE)) {
  row.names <- compatRowNames(row.names)
  if (length(n) != 1) stopc("`n` must be scalar")
  if (is.na(n)) {
    n <- 256L
  } else if (n < -1) {
    stopc("`n` must be nonnegative or -1")
  }
  if (is.infinite(n)) n <- -1
  if (trunc(n) != n) stopc("`n` must be a whole number")
  ret <- result_fetch(res@ptr, n = n)
  ret <- convert_bigint(ret, res@bigint)
  ret <- sqlColumnToRownames(ret, row.names)
  ret
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbFetch", "SQLiteResult", dbFetch_SQLiteResult)
