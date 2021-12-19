#' @rdname SQLiteConnection-class
#' @param temporary If `TRUE`, only temporary tables are considered.
#' @param fail_if_missing If `FALSE`, `dbRemoveTable()` succeeds if the
#'   table doesn't exist.
#' @usage NULL
dbRemoveTable_SQLiteConnection_character <- function(conn, name, ..., temporary = FALSE, fail_if_missing = TRUE) {
  name <- check_quoted_identifier(name)
  name <- dbQuoteIdentifier(conn, name)

  if (fail_if_missing) {
    extra <- ""
  } else {
    extra <- "IF EXISTS "
  }
  if (temporary) {
    extra <- paste0(extra, "temp.")
  }

  dbExecute(conn, paste0("DROP TABLE ", extra, name))
  invisible(TRUE)
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbRemoveTable", c("SQLiteConnection", "character"), dbRemoveTable_SQLiteConnection_character)
