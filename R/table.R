#' @include SQLiteConnection.R
NULL

match_col <- function(value, col_names) {
  if (length(col_names) == length(value)) {
    if (!all(names(value) == col_names)) {
      if (all(tolower(names(value)) == tolower(col_names))) {
        warning("Column names will be matched ignoring character case",
          call. = FALSE
        )
        names(value) <- col_names
        return(value)
      }
    }
  }

  if (!all(names(value) %in% col_names)) {
    stop("Columns ",
      paste0("`", setdiff(names(value), col_names), "`", collapse = ", "),
      " not found",
      call. = FALSE
    )
  }

  value
}

field_def <- function(conn, data, field_types) {
  # Match column names with compatibility rules
  new_field_types <- match_col(field_types, names(data))

  # Automatic types for all other fields
  auto_field_types <- db_data_types(conn, data[setdiff(names(data), names(field_types))])
  field_types[names(auto_field_types)] <- auto_field_types

  # Reorder
  field_types <- field_types[names(data)]

  field_types
}

db_data_types <- function(conn, data) {
  vcapply(data, function(x) dbDataType(conn, x))
}

check_quoted_identifier <- function(name) {
  name
}

sqliteListTables <- function(conn) {
  sql <- sqliteListTablesQuery(conn)
  dbSendQuery(conn, sql)
}

sqliteListTablesWithName <- function(conn, name) {
  # Also accept quoted identifiers
  id <- as.list(dbUnquoteIdentifier(conn, dbQuoteIdentifier(conn, name))[[1]]@name)
  schema <- id[["schema"]]
  table <- id[["table"]]

  sql <- sqliteListTablesQuery(conn, schema, SQL("$name"))
  rs <- dbSendQuery(conn, sql)
  dbBind(rs, list(name = tolower(table)))
  rs
}

sqliteListTablesQuery <- function(conn, schema = NULL, name = NULL) {
  if (is.null(schema)) {
    info_sql <- "(SELECT * FROM sqlite_master UNION ALL SELECT * FROM sqlite_temp_master)"
  } else {
    info_sql <- paste0("(SELECT * FROM ", dbQuoteIdentifier(conn, schema), ".sqlite_master)")
  }

  SQL(paste0("SELECT name ",
    "FROM ", info_sql, " ",
    "WHERE (type = 'table' OR type = 'view') ",
    if (!is.null(name)) paste0("AND (lower(name) = ", dbQuoteString(conn, name), ") "),
    "ORDER BY name",
    sep = "\n"
  ))
}
