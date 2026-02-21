#' @rdname SQLiteConnection-class
#' @usage NULL
dbListObjects_SQLiteConnection <- function(conn, prefix = NULL, ...) {
  if (!is.null(prefix)) {
    id <- as.list(dbUnquoteIdentifier(conn, dbQuoteIdentifier(conn, prefix))[[1]]@name)
    # `Id(schema = "mydb")` round-trips through dbQuoteIdentifier/dbUnquoteIdentifier
    # as a single-component identifier (table slot), so fall back to table if schema is absent.
    schema <- id[["schema"]] %||% id[["table"]]

    sql <- sqliteListTablesQuery(conn, schema)
    rs <- dbSendQuery(conn, sql)
    on.exit(dbClearResult(rs), add = TRUE)
    names <- dbFetch(rs)$name

    tables <- lapply(names, function(t) Id(schema = schema, table = t))
    is_prefix <- rep(FALSE, length(tables))
  } else {
    schemas <- dbGetQuery(conn, "SELECT name FROM pragma_database_list;")$name
    schema_ids <- lapply(schemas, function(s) Id(schema = s))

    table_names <- dbListTables(conn)
    table_ids <- lapply(table_names, function(t) Id(table = t))

    tables <- c(schema_ids, table_ids)
    is_prefix <- c(rep(TRUE, length(schema_ids)), rep(FALSE, length(table_ids)))
  }

  data.frame(
    table = I(unname(tables)),
    is_prefix = is_prefix,
    stringsAsFactors = FALSE
  )
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbListObjects", "SQLiteConnection", dbListObjects_SQLiteConnection)
