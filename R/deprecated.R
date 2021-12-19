#' @include SQLiteConnection.R
NULL

#' Build the SQL CREATE TABLE definition as a string
#'
#' The output SQL statement is a simple `CREATE TABLE` suitable for
#' `dbGetQuery`
#'
#' @param con A database connection.
#' @param name Name of the new SQL table
#' @param value A data.frame, for which we want to create a table.
#' @param field.types Optional, named character vector of the types for each
#'   field in `value`
#' @param row.names Logical. Should row.name of `value` be exported as a
#'   `row_names` field? Default is `TRUE`
#' @return An SQL string
#' @keywords internal
#' @aliases dbBuildTableDefinition
#' @export
sqliteBuildTableDefinition <- function(con, name, value, field.types = NULL,
                                       row.names = pkgconfig::get_config("RSQLite::row.names.query", FALSE)) {

  warning_once("RSQLite::sqliteBuildTableDefinition() is deprecated, please switch to DBI::sqlCreateTable().")
  row.names <- compatRowNames(row.names)

  if (!is.data.frame(value)) {
    value <- as.data.frame(value)
  }
  value <- sqlColumnToRownames(value, row.names)

  if (is.null(field.types)) {
    field.types <- vapply(value, dbDataType,
      dbObj = con,
      FUN.VALUE = character(1)
    )
  }
  # Escape field names
  names(field.types) <- dbQuoteIdentifier(con, names(field.types))

  flds <- paste(names(field.types), field.types)
  paste("CREATE TABLE", name, "\n(", paste(flds, collapse = ",\n\t"), "\n)")
}

#' @export
dbBuildTableDefinition <- function(...) {
  warning_once("RSQLite::dbBuildTableDefinition() is deprecated, please switch to DBI::sqlCreateTable().")
  sqliteBuildTableDefinition(...)
}

#' isIdCurrent
#'
#' Deprecated. Please use dbIsValid instead.
#'
#' @keywords internal
#' @export
isIdCurrent <- function(obj) {
  .Deprecated("dbIsValid")
  dbIsValid(obj)
}

#' Deprecated querying tools
#'
#' These functions have been deprecated. Please switch to using
#' [dbSendQuery()]/[dbGetQuery()] with the `params` argument
#' or with calling [dbBind()] instead.
#'
#' @keywords internal
#' @name query-dep
NULL

#' Return an entire column from a SQLite database
#'
#' A shortcut for
#' \code{\link[DBI]{dbReadTable}(con, table, select.cols = column, row.names = FALSE)[[1]]},
#' kept for compatibility reasons.
#'
#' @keywords internal
#' @export
sqliteQuickColumn <- function(con, table, column) {
  dbGetQuery(con, paste("SELECT ", column, " FROM ", table), row.names = FALSE)[[1]]
}
