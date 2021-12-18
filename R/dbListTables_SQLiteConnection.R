#' @rdname SQLiteConnection-class
#' @usage NULL
dbListTables_SQLiteConnection <- function(conn, ...) {
  rs <- sqliteListTables(conn)
  on.exit(dbClearResult(rs), add = TRUE)

  dbFetch(rs)$name
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbListTables", "SQLiteConnection", dbListTables_SQLiteConnection)
