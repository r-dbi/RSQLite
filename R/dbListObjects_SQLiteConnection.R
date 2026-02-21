#' @rdname SQLiteConnection-class
#' @usage NULL
dbListObjects_SQLiteConnection <- function(conn, prefix = NULL, ...) {
  if (!is.null(prefix)) {
    id <- as.list(dbUnquoteIdentifier(conn, dbQuoteIdentifier(conn, prefix))[[1]]@name)
    # `Id(schema = "mydb")` round-trips through dbQuoteIdentifier/dbUnquoteIdentifier
    # as a single-component identifier (table slot), so fall back to table if schema is absent.
    schema <- id[["schema"]] %||% id[["table"]]

    sql <- sqliteListTablesQuery(conn, schema)
    rs <- dbSendQuery_SQLiteConnection_character(conn, sql)
    on.exit(dbClearResult_SQLiteResult(rs), add = TRUE)
    names <- dbFetch_SQLiteResult(rs)$name

    tables <- lapply(names, function(t) Id(schema = schema, table = t))
    is_prefix <- rep(FALSE, length(tables))
  } else {
    rs <- dbSendQuery_SQLiteConnection_character(conn, "SELECT name FROM pragma_database_list;")
    on.exit(dbClearResult_SQLiteResult(rs), add = TRUE)
    schemas <- dbFetch_SQLiteResult(rs)$name
    dbClearResult_SQLiteResult(rs)
    on.exit(NULL, add = FALSE)
    schema_ids <- lapply(schemas, function(s) Id(schema = s))

    table_names <- dbListTables_SQLiteConnection(conn)
    table_ids <- lapply(table_names, function(t) Id(table = t))

    tables <- c(table_ids, schema_ids)
    is_prefix <- c(rep(FALSE, length(table_ids)), rep(TRUE, length(schema_ids)))
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
