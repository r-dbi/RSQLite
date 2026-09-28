#' @rdname SQLiteConnection-class
#' @inheritParams DBI::dbAppendTableArrow
#' @usage NULL
dbAppendTableArrow_SQLiteConnection <- function(conn, name, value, ...) {
  value <- nanoarrow::as_nanoarrow_array_stream(value)
  fields <- arrow_schema_names(nanoarrow::infer_nanoarrow_schema(value))
  if (length(fields) == 0L) {
    stopc("`value` must have at least one column")
  }

  name <- dbQuoteIdentifier(conn, name)
  if (length(name) != 1L) {
    stopc("`name` must identify a single table")
  }

  savepoint_id <- get_savepoint_id("dbAppendTableArrow")
  dbBegin(conn, name = savepoint_id)
  on.exit(dbRollback(conn, name = savepoint_id))

  sql <- SQL(paste0(
    "INSERT INTO ", name, "\n",
    "  (", paste(dbQuoteIdentifier(conn, fields), collapse = ", "), ")\n",
    "VALUES\n",
    "  (", paste(rep("?", length(fields)), collapse = ", "), ")"
  ))

  rs <- dbSendStatement(conn, sql)
  on.exit(dbClearResult(rs), add = TRUE, after = FALSE)
  # Bound by position: the placeholders are anonymous
  result_bind_arrow(rs@ptr, value, seq_along(fields) - 1L)
  rows <- dbGetRowsAffected(rs)
  dbClearResult(rs)

  on.exit(NULL)
  dbCommit(conn, name = savepoint_id)
  rows
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbAppendTableArrow", "SQLiteConnection", dbAppendTableArrow_SQLiteConnection)
