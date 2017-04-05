#' Class SQLiteConnection
#'
#' `SQLiteConnection` objects are usually created by
#' [DBI::dbConnect()].
#'
#' @seealso
#' The corresponding generic functions
#' [DBI::dbSendQuery()], [DBI::dbGetQuery()],
#' [DBI::dbSendStatement()], and [DBI::dbExecute()].
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
setMethod("dbQuoteIdentifier", c("SQLiteConnection", "character"), function(conn, x, ...) {
  if (any(is.na(x))) {
    stop("Cannot pass NA to dbQuoteIdentifier()", call. = FALSE)
  }
  x <- gsub("`", "``", x, fixed = TRUE)
  if (length(x) == 0L) {
    SQL(character())
  } else {
    # Not calling encodeString() here to keep things simple
    SQL(paste("`", x, "`", sep = ""))
  }
})

#' @rdname SQLiteConnection-class
#' @export
setMethod("dbQuoteIdentifier", c("SQLiteConnection", "SQL"), function(conn, x, ...) {
  SQL(x)
})

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
setMethod("dbIsValid", "SQLiteConnection", function(dbObj, ...) {
  rsqlite_connection_valid(dbObj@ptr)
})

#' @rdname SQLiteConnection-class
#' @export
setMethod("dbGetException", "SQLiteConnection", function(conn, ...) {
  warning_once("RSQLite::dbGetException() is deprecated, please switch to using standard error handling via tryCatch().")
  list(
    errorNum = 0L,
    errorMsg = "OK"
  )
})
