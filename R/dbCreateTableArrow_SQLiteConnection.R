#' @rdname SQLiteConnection-class
#' @inheritParams DBI::dbCreateTableArrow
#' @usage NULL
dbCreateTableArrow_SQLiteConnection <- function(conn, name, value, ..., field.types = NULL, temporary = FALSE) {
  if (!is.logical(temporary) || length(temporary) != 1L || is.na(temporary)) {
    stopc("`temporary` must be a logical scalar")
  }
  if (!is.null(field.types) && !(is.character(field.types) && !is.null(names(field.types)) && !anyDuplicated(names(field.types)))) {
    stopc("`field.types` must be a named character vector with unique names, or NULL")
  }

  if (inherits(value, "nanoarrow_schema")) {
    schema <- value
  } else {
    schema <- nanoarrow::infer_nanoarrow_schema(value)
  }

  fields <- field_def(conn, arrow_ptype(schema), field.types)

  dbCreateTable(
    conn = conn,
    name = name,
    fields = fields,
    ...,
    temporary = temporary
  )
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbCreateTableArrow", "SQLiteConnection", dbCreateTableArrow_SQLiteConnection)
