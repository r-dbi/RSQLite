# show()
#' @rdname SQLiteConnection-class
#' @usage NULL
show_SQLiteConnection <- function(object) {
  cat("<SQLiteConnection>\n")
  if (dbIsValid(object)) {
    cat("  Path: ", object@dbname, "\n", sep = "")
    cat("  Extensions: ", object@loadable.extensions, "\n", sep = "")
  } else {
    cat("  DISCONNECTED\n")
  }
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("show", "SQLiteConnection", show_SQLiteConnection)
