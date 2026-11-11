#' @rdname SQLiteConnection-class
#' @inheritParams DBI::dbWriteTableArrow
#' @param field.types character vector of named SQL field types where the names are the names of new table's columns.
#'   If missing, types inferred with [DBI::dbDataType()]).
#' @usage NULL
dbWriteTableArrow_SQLiteConnection <- function(conn, name, value, append = FALSE, overwrite = FALSE, ...,
                                               temporary = FALSE, field.types = NULL) {
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    stopc("`overwrite` must be a logical scalar")
  }
  if (!is.logical(append) || length(append) != 1L || is.na(append)) {
    stopc("`append` must be a logical scalar")
  }
  if (!is.logical(temporary) || length(temporary) != 1L || is.na(temporary)) {
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

  value <- nanoarrow::as_nanoarrow_array_stream(value)

  name <- check_quoted_identifier(name)

  savepoint_id <- get_savepoint_id("dbWriteTableArrow")
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
    dbCreateTableArrow(
      conn = conn,
      name = name,
      value = value,
      field.types = field.types,
      temporary = temporary
    )
  }

  dbAppendTableArrow(conn = conn, name = name, value = value)

  dbCommit(conn, name = savepoint_id)
  on.exit(NULL)
  invisible(TRUE)
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbWriteTableArrow", "SQLiteConnection", dbWriteTableArrow_SQLiteConnection)
