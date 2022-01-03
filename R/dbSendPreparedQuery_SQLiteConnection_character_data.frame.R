#' @rdname query-dep
#' @param bind.data A data frame of data to be bound.
#' @usage NULL
dbSendPreparedQuery_SQLiteConnection_character_data.frame <- function(conn, statement, bind.data, ...) {
  warning_once("RSQLite::dbSendPreparedQuery() is deprecated, please switch to DBI::dbSendQuery(params = bind.data).")

  res <- dbSendQuery(conn, statement)

  tryCatch(
    db_bind(res, unclass(bind.data), allow_named_superset = TRUE),
    error = function(e) {
      db_bind(res, unclass(unname(bind.data)), allow_named_superset = FALSE)
    }
  )
  res
}
#' @rdname query-dep
#' @export
setMethod("dbSendPreparedQuery", c("SQLiteConnection", "character", "data.frame"), dbSendPreparedQuery_SQLiteConnection_character_data.frame)
