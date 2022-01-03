#' @rdname SQLiteConnection-class
#' @usage NULL
dbUnquoteIdentifier_SQLiteConnection_SQL <- function(conn, x, ...) {
  id_rx <- "(?:`((?:[^`]|``)+)`|([^`. ]+))"

  rx <- paste0(
    "^",
    "(?:|", id_rx, "[.])",
    "(?:|", id_rx, ")",
    "$"
  )

  bad <- grep(rx, x, invert = TRUE)
  if (length(bad) > 0) {
    stop("Can't unquote ", x[bad[[1]]], call. = FALSE)
  }
  schema <- gsub(rx, "\\1\\2", x)
  schema <- gsub("``", "`", schema)
  table <- gsub(rx, "\\3\\4", x)
  table <- gsub("``", "`", table)

  ret <- Map(schema, table, f = as_table)
  names(ret) <- names(x)
  ret
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbUnquoteIdentifier", c("SQLiteConnection", "SQL"), dbUnquoteIdentifier_SQLiteConnection_SQL)
