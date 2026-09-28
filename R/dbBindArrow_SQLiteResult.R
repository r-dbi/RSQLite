#' @rdname SQLiteResult-class
#' @inheritParams DBI::dbBindArrow
#' @usage NULL
dbBindArrow_SQLiteResult <- function(res, params, ...) {
  params <- nanoarrow::as_nanoarrow_array_stream(params)
  db_bind_arrow(res, params)
  invisible(res)
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbBindArrow", "SQLiteResult", dbBindArrow_SQLiteResult)
