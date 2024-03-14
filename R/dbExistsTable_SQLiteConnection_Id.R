#' @rdname SQLiteConnection-class
#' @usage NULL
dbExistsTable_SQLiteConnection_Id <- function(conn, name, ...) {
  stopifnot(is(name, "Id"))

  id <- as.list(dbUnquoteIdentifier(conn, dbQuoteIdentifier(conn, name))[[1]]@name)
  schema <- id$schema
  table <- id$table

  if (!is.null(schema)) {
    schemas <- dbGetQuery(conn, "SELECT name FROM pragma_database_list;")$name

    if (!(schema %in% schemas)) {
      return(FALSE)
    }
  }

  sql <- sqliteListTablesQuery(conn, schema, SQL("$name"))
  rs <- dbSendQuery(conn, sql)
  dbBind(rs, list(name = tolower(table)))
  on.exit(dbClearResult(rs), add = TRUE)

  nrow(dbFetch(rs, 1L)) > 0
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbExistsTable", c("SQLiteConnection", "Id"), dbExistsTable_SQLiteConnection_Id)
