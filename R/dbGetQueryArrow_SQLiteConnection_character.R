#' @rdname SQLiteConnection-class
#' @usage NULL
dbGetQueryArrow_SQLiteConnection_character <- function(conn, statement, ..., schema = NULL) {
  rs <- dbSendQueryArrow(conn, statement, ..., schema = schema)
  on.exit(dbClearResult(rs))
  dbFetchArrow(rs, ...)
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbGetQueryArrow", c("SQLiteConnection", "character"), dbGetQueryArrow_SQLiteConnection_character)
