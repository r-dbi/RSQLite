#' @rdname SQLiteResult-class
#' @usage NULL
dbBind_SQLiteResult <- function(res, params, ...) {
  db_bind(res, as.list(params), ..., allow_named_superset = FALSE)
}
#' @rdname SQLiteResult-class
#' @export
setMethod("dbBind", "SQLiteResult", dbBind_SQLiteResult)
