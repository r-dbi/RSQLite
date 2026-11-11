#' @rdname SQLiteConnection-class
#' @usage NULL
dbReadTableArrow_SQLiteConnection <- function(conn, name, ..., schema = NULL) {
  # Any name that dbQuoteIdentifier() takes, such as a string, `SQL()` or `Id()`
  name <- dbQuoteIdentifier(conn, check_quoted_identifier(name))
  if (length(name) != 1L) {
    stopc("Invalid name: ", format(name))
  }
  dbGetQueryArrow(conn, paste0("SELECT * FROM ", name), schema = schema)
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbReadTableArrow", "SQLiteConnection", dbReadTableArrow_SQLiteConnection)
