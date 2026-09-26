#' @rdname SQLiteConnection-class
#' @usage NULL
dbReadTableArrow_SQLiteConnection_character <- function(conn, name, ..., schema = NULL) {
  name <- check_quoted_identifier(name)
  name <- dbQuoteIdentifier(conn, name)
  dbGetQueryArrow(conn, paste0("SELECT * FROM ", name), schema = schema)
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbReadTableArrow", c("SQLiteConnection", "character"), dbReadTableArrow_SQLiteConnection_character)
