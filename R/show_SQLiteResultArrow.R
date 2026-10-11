#' @rdname SQLiteResultArrow-class
#' @usage NULL
show_SQLiteResultArrow <- function(object) {
  cat("<SQLiteResultArrow>\n")
  if (!dbIsValid(object)) {
    cat("  EXPIRED\n")
    return(invisible(NULL))
  }

  cat("  SQL  ", dbGetStatement(object), "\n", sep = "")
  done <- if (dbHasCompleted(object)) "complete" else "incomplete"
  cat("  ROWS Fetched: ", dbGetRowCount(object), " [", done, "]\n", sep = "")
  cat("       Changed: ", dbGetRowsAffected(object), "\n", sep = "")
  invisible(NULL)
}
#' @rdname SQLiteResultArrow-class
#' @export
setMethod("show", "SQLiteResultArrow", show_SQLiteResultArrow)
