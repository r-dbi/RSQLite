#' Class SQLiteConnection.
#'
#' \code{SQLiteConnection} objects are usually created by
#' \code{\link[DBI]{dbConnect}}.
#'
#' @keywords internal
#' @export
setClass("SQLiteConnection",
  contains = "DBIConnection",
  slots = list(
    ptr = "externalptr",
    dbname = "character",
    loadable.extensions = "logical",
    flags = "integer",
    vfs = "character",
    ref = "environment"
  )
)

#' @rdname SQLiteConnection-class
#' @export
setMethod("show", "SQLiteConnection", function(object) {
  cat("<SQLiteConnection>\n")
  if (dbIsValid(object)) {
    cat("  Path: ", object@dbname, "\n", sep = "")
    cat("  Extensions: ", object@loadable.extensions, "\n", sep = "")
  } else {
    cat("  DISCONNECTED\n")
  }
})

#' @rdname SQLiteConnection-class
#' @export
setMethod("dbIsValid", "SQLiteConnection", function(dbObj) {
  rsqlite_connection_valid(dbObj@ptr)
})

#' @rdname SQLiteConnection-class
#' @export
setMethod("dbGetException", "SQLiteConnection", function(conn) {
  .Deprecated("tryCatch", old = "dbGetException")
  rsqlite_get_exception(conn@ptr)
})
