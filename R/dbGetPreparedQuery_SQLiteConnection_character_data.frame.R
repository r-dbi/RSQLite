#' @rdname query-dep
#' @usage NULL
dbGetPreparedQuery_SQLiteConnection_character_data.frame <- function(conn, statement, bind.data, ...) {
  warning_once("RSQLite::dbGetPreparedQuery() is deprecated, please switch to DBI::dbGetQuery(params = bind.data).")

  res <- dbSendQuery(conn, statement)
  on.exit(dbClearResult(res), add = TRUE)

  bind.data <- as.list(bind.data)

  tryCatch(
    db_bind(res, bind.data, allow_named_superset = TRUE),
    error = function(e) {
      db_bind(res, unname(bind.data), allow_named_superset = FALSE)
    }
  )
  dbFetch(res)
}
#' @rdname query-dep
#' @export
setMethod("dbGetPreparedQuery", c("SQLiteConnection", "character", "data.frame"), dbGetPreparedQuery_SQLiteConnection_character_data.frame)
