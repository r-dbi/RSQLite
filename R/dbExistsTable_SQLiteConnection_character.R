#' @rdname SQLiteConnection-class
#' @usage NULL
dbExistsTable_SQLiteConnection_character <- function(conn, name, ...) {
  stopifnot(length(name) == 1L)
  rs <- sqliteListTablesWithName(conn, name)
  on.exit(dbClearResult(rs), add = TRUE)

  nrow(dbFetch(rs, 1L)) > 0
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbExistsTable", c("SQLiteConnection", "character"), dbExistsTable_SQLiteConnection_character)
