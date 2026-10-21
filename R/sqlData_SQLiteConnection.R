#' @rdname SQLiteConnection-class
#' @usage NULL
sqlData_SQLiteConnection <- function(con, value,
                                     row.names = FALSE,
                                     ...) {
  if (missing(row.names)) {
    row.names <- row_names_default("RSQLite::row.names.query")
  }
  value <- sql_data(value, row.names)
  value <- quote_string(value, con)

  value
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("sqlData", "SQLiteConnection", sqlData_SQLiteConnection)
