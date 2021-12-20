#' @param header is a logical indicating whether the first data line (but see
#'   `skip`) has a header or not.  If missing, it value is determined
#'   following [read.table()] convention, namely, it is set to TRUE if
#'   and only if the first row has one fewer field that the number of columns.
#' @param sep The field separator, defaults to `','`.
#' @param eol The end-of-line delimiter, defaults to `'\n'`.
#' @param skip number of lines to skip before reading the data. Defaults to 0.
#' @param nrows Number of rows to read to determine types.
#' @param colClasses Character vector of R type names, used to override
#'   defaults when imputing classes from on-disk file.
#' @rdname dbWriteTable
#' @usage NULL
dbWriteTable_SQLiteConnection_character_character <- function(conn, name, value, ..., field.types = NULL, overwrite = FALSE,
                                                              append = FALSE, header = TRUE, colClasses = NA, row.names = FALSE,
                                                              nrows = 50, sep = ",", eol = "\n", skip = 0, temporary = FALSE) {
  if (overwrite && append) {
    stop("overwrite and append cannot both be TRUE")
  }
  value <- path.expand(value)

  row.names <- compatRowNames(row.names)

  savepoint_id <- get_savepoint_id("dbWriteTable")
  dbBegin(conn, name = savepoint_id)
  on.exit(dbRollback(conn, name = savepoint_id))

  found <- dbExistsTable(conn, name)
  if (found && !overwrite && !append) {
    stop("Table ", name, " exists in database, and both overwrite and",
      " append are FALSE",
      call. = FALSE
    )
  }
  if (found && overwrite) {
    dbRemoveTable(conn, name)
  }

  if (!found || overwrite) {
    # Initialise table with first `nrows` lines
    if (is.null(field.types)) {
      fields <- utils::read.table(
        value,
        sep = sep, header = header, skip = skip, nrows = nrows,
        na.strings = "\\N", comment.char = "", colClasses = colClasses,
        stringsAsFactors = FALSE
      )
    } else {
      fields <- field.types
    }
    sql <- sqlCreateTable(conn, name, fields,
      row.names = FALSE,
      temporary = temporary
    )
    dbExecute(conn, sql)
  }

  skip <- skip + as.integer(header)
  connection_import_file(conn@ptr, name, value, sep, eol, skip)

  dbCommit(conn, name = savepoint_id)
  on.exit(NULL)
  invisible(TRUE)
}
#' @rdname dbWriteTable
#' @export
setMethod("dbWriteTable", c("SQLiteConnection", "character", "character"), dbWriteTable_SQLiteConnection_character_character)
