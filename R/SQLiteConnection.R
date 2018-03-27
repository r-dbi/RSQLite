#' Class SQLiteConnection (and methods)
#'
#' SQLiteConnection objects are created by passing [SQLite()] as first
#' argument to [DBI::dbConnect()].
#' They are a superclass of the [DBIConnection-class] class.
#' The "Usage" section lists the class methods overridden by \pkg{RSQLite}.
#'
#' @seealso
#' The corresponding generic functions
#' [DBI::dbSendQuery()], [DBI::dbGetQuery()],
#' [DBI::dbSendStatement()], [DBI::dbExecute()],
#' [DBI::dbExistsTable()], [DBI::dbListTables()], [DBI::dbListFields()],
#' [DBI::dbRemoveTable()], and [DBI::sqlData()].
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

# show()
#' @export
#' @rdname SQLiteConnection-class
setMethod("show", "SQLiteConnection", function(object) {
  cat("<SQLiteConnection>\n")
  if (dbIsValid(object)) {
    cat("  Path: ", object@dbname, "\n", sep = "")
    cat("  Extensions: ", object@loadable.extensions, "\n", sep = "")
  } else {
    cat("  DISCONNECTED\n")
  }
})

# dbIsValid()
#' @export
#' @rdname SQLiteConnection-class
setMethod("dbIsValid", "SQLiteConnection", function(dbObj, ...) {
  connection_valid(dbObj@ptr)
})

# dbDisconnect()

# dbSendQuery()

# dbSendStatement()

# dbDataType()

# dbQuoteString()

# dbQuoteIdentifier()
#' @export
#' @rdname SQLiteConnection-class
setMethod("dbQuoteIdentifier", c("SQLiteConnection", "character"), function(conn, x, ...) {
  if (any(is.na(x))) {
    stop("Cannot pass NA to dbQuoteIdentifier()", call. = FALSE)
  }
  # Avoid fixed = TRUE due to https://github.com/r-dbi/DBItest/issues/156
  x <- gsub("`", "``", enc2utf8(x))
  if (length(x) == 0L) {
    SQL(character(), names = names(x))
  } else {
    # Not calling encodeString() here to keep things simple
    SQL(paste("`", x, "`", sep = ""), names = names(x))
  }
})

#' @rdname SQLiteConnection-class
#' @export
setMethod("dbQuoteIdentifier", c("SQLiteConnection", "SQL"), function(conn, x, ...) {
  x
})

#' @rdname SQLiteConnection-class
#' @export
setMethod("dbUnquoteIdentifier", c("SQLiteConnection", "SQL"), function(conn, x, ...) {
  rx <- '^(?:(?:|`((?:[^`]|``)+)`[.])(?:|`((?:[^`]|``)*)`)|([^`. ]+))$'
  bad <- grep(rx, x, invert = TRUE)
  if (length(bad) > 0) {
    stop("Can't unquote ", x[bad[[1]]], call. = FALSE)
  }
  schema <- gsub(rx, "\\1", x)
  schema <- gsub("``", "`", schema)
  table <- gsub(rx, "\\2", x)
  table <- gsub("``", "`", table)
  naked_table <- gsub(rx, "\\3", x)

  ret <- Map(schema, table, naked_table, f = as_table)
  names(ret) <- names(x)
  ret
})

as_table <- function(schema, table, naked_table = NULL) {
  args <- c(schema = schema, table = table, table = naked_table)
  # Also omits NA args
  args <- args[!is.na(args) & args != ""]
  do.call(Id, as.list(args))
}

# dbWriteTable()

# dbReadTable()

# dbListTables()

# dbExistsTable()

# dbListFields()

# dbRemoveTable()

# dbBegin()

# dbCommit()

# dbRollback()

# other

#' @rdname SQLiteConnection-class
#' @export
setMethod("dbGetException", "SQLiteConnection", function(conn, ...) {
  warning_once("RSQLite::dbGetException() is deprecated, please switch to using standard error handling via tryCatch().")
  list(
    errorNum = 0L,
    errorMsg = "OK"
  )
})

