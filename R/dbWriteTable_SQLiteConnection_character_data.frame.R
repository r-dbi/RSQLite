#' Write a local data frame or file to the database
#'
#' Functions for writing data frames or delimiter-separated files
#' to database tables.
#'
#' @seealso
#' The corresponding generic function [DBI::dbWriteTable()].
#'
#' @rdname dbWriteTable
#' @param conn a \code{\linkS4class{SQLiteConnection}} object, produced by
#'   [DBI::dbConnect()]
#' @param name a character string specifying a table name. SQLite table names
#'   are \emph{not} case sensitive, e.g., table names `ABC` and `abc`
#'   are considered equal.
#' @param value a data.frame (or coercible to data.frame) object or a
#'   file name (character).  In the first case, the data.frame is
#'   written to a temporary file and then imported to SQLite; when `value`
#'   is a character, it is interpreted as a file name and its contents imported
#'   to SQLite.
#' @param row.names A logical specifying whether the `row.names` should be
#'   output to the output DBMS table; if `TRUE`, an extra field whose name
#'   will be whatever the R identifier `"row.names"` maps to the DBMS (see
#'   [DBI::make.db.names()]). If `NA` will add rows names if
#'   they are characters, otherwise will ignore.
#' @param overwrite a logical specifying whether to overwrite an existing table
#'   or not. Its default is `FALSE`.
#' @param append a logical specifying whether to append to an existing table
#'   in the DBMS.  Its default is `FALSE`.
#' @param field.types character vector of named  SQL field types where
#'   the names are the names of new table's columns. If missing, types inferred
#'   with [DBI::dbDataType()]).
#' @param temporary a logical specifying whether the new table should be
#'   temporary. Its default is `FALSE`.
#' @param ... Needed for compatibility with generic. Otherwise ignored.
#' @details In a primary key column qualified with
#' \href{https://www.sqlite.org/autoinc.html}{`AUTOINCREMENT`}, missing
#' values will be assigned the next largest positive integer,
#' while nonmissing elements/cells retain their value.  If the
#' autoincrement column exists in the data frame
#' passed to the `value` argument,
#' the `NA` elements are overwritten.
#' Similarly, if the key column is not present in the data frame, all
#' elements are automatically assigned a value.
#'
#' When `value` is a character string, it is interpreted as the path to a local
#' delimiter-separated text file and imported directly into SQLite. Use `sep` to
#' set the field separator, for example `sep = "\t"` for tab-separated files,
#' and `header`, `skip`, `eol`, `nrows`, and `colClasses` to control parsing and
#' type inference. Files are read from the local filesystem; compressed files
#' are not decompressed automatically.
#' @examples
#' con <- dbConnect(SQLite())
#' dbWriteTable(con, "mtcars", mtcars)
#' dbReadTable(con, "mtcars")
#'
#' # A zero row data frame just creates a table definition.
#' dbWriteTable(con, "mtcars2", mtcars[0, ])
#' dbReadTable(con, "mtcars2")
#'
#' # Import a CSV file without first reading it into R.
#' csv <- tempfile(fileext = ".csv")
#' write.table(
#'   data.frame(id = 1:2, name = c("Ada", "Grace")),
#'   csv,
#'   sep = ",",
#'   row.names = FALSE,
#'   quote = FALSE
#' )
#' dbWriteTable(con, "people_csv", csv, overwrite = TRUE)
#' dbReadTable(con, "people_csv")
#'
#' # Import a tab-separated file by setting sep = "\t".
#' tsv <- tempfile(fileext = ".tsv")
#' write.table(
#'   data.frame(id = 1:2, score = c(10, 20)),
#'   tsv,
#'   sep = "\t",
#'   row.names = FALSE,
#'   quote = FALSE
#' )
#' dbWriteTable(con, "scores_tsv", tsv, sep = "\t", overwrite = TRUE)
#' dbReadTable(con, "scores_tsv")
#'
#' dbDisconnect(con)
#' @usage NULL
dbWriteTable_SQLiteConnection_character_data.frame <- function(conn, name, value, ...,
                                                               row.names = pkgconfig::get_config("RSQLite::row.names.table", FALSE),
                                                               overwrite = FALSE, append = FALSE,
                                                               field.types = NULL, temporary = FALSE) {
  row.names <- compatRowNames(row.names)

  if ((!is.logical(row.names) && !is.character(row.names)) || length(row.names) != 1L) {
    stopc("`row.names` must be a logical scalar or a string")
  }
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    stopc("`overwrite` must be a logical scalar")
  }
  if (!is.logical(append) || length(append) != 1L || is.na(append)) {
    stopc("`append` must be a logical scalar")
  }
  if (!is.logical(temporary) || length(temporary) != 1L) {
    stopc("`temporary` must be a logical scalar")
  }
  if (overwrite && append) {
    stopc("overwrite and append cannot both be TRUE")
  }
  if (!is.null(field.types) && !(is.character(field.types) && !is.null(names(field.types)) && !anyDuplicated(names(field.types)))) {
    stopc("`field.types` must be a named character vector with unique names, or NULL")
  }
  if (append && !is.null(field.types)) {
    stopc("Cannot specify `field.types` with `append = TRUE`")
  }

  name <- check_quoted_identifier(name)

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

  value <- sql_data(value, row.names = row.names)

  if (!found || overwrite) {
    fields <- field_def(conn, value, field.types)

    dbCreateTable(
      conn = conn,
      name = name,
      fields = fields,
      temporary = temporary
    )
  } else if (append) {
    col_names <- dbListFields(conn, name)
    value <- match_col(value, col_names)
  }

  if (nrow(value) > 0) {
    dbAppendTable(
      conn = conn,
      name = name,
      value = value
    )
  }

  dbCommit(conn, name = savepoint_id)
  on.exit(NULL)
  invisible(TRUE)
}
#' @rdname dbWriteTable
#' @export
setMethod("dbWriteTable", c("SQLiteConnection", "character", "data.frame"), dbWriteTable_SQLiteConnection_character_data.frame)
