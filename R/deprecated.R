#' @include SQLiteConnection.R
NULL

#' @rdname query-dep
#'
#' @param conn A `DBIConnection` object.
#' @param statement A SQL string
#' @param bind.data A data frame
#' @param ... Other arguments used by methods
#' @export
setGeneric("dbSendPreparedQuery", function(conn, statement, bind.data, ...) {
  standardGeneric("dbSendPreparedQuery")
})

#' @rdname query-dep
#' @export
setGeneric("dbGetPreparedQuery", function(conn, statement, bind.data, ...) {
  standardGeneric("dbGetPreparedQuery")
})

#' Generic for creating a new transaction
#'
#' See method documentation for details.
#'
#' @export
#' @param conn A `DBIConnection` object.
#' @param ... Other arguments used by methods
#' @keywords internal
setGeneric("dbBeginTransaction", function(conn, ...) {
  .Deprecated("dbBegin", old = "dbBeginTransaction")
  dbBegin(conn, ...)
})

#' Build the SQL CREATE TABLE definition as a string
#'
#' The output SQL statement is a simple `CREATE TABLE` suitable for
#' `dbGetQuery`
#'
#' @param conn A database connection.
#' @param name Name of the new SQL table
#' @param value A data.frame, for which we want to create a table.
#' @param field.types Optional, named character vector of the types for each
#'   field in `value`
#' @param row.names Logical. Should row.name of `value` be exported as a
#'   `row_names` field? Default is `TRUE`
#' @return An SQL string
#' @keywords internal
#' @aliases dbBuildTableDefinition
#' @export
sqliteBuildTableDefinition <- function(con, name, value, field.types = NULL,
                                       row.names = pkgconfig::get_config("RSQLite::row.names.query", FALSE)) {

  warning_once("RSQLite::sqliteBuildTableDefinition() is deprecated, please switch to DBI::sqlCreateTable().")
  row.names <- compatRowNames(row.names)

  if (!is.data.frame(value)) {
    value <- as.data.frame(value)
  }
  value <- sqlColumnToRownames(value, row.names)

  if (is.null(field.types)) {
    field.types <- vapply(value, dbDataType, dbObj = con,
      FUN.VALUE = character(1))
  }
  # Escape field names
  names(field.types) <- dbQuoteIdentifier(con, names(field.types))

  flds <- paste(names(field.types), field.types)
  paste("CREATE TABLE", name, "\n(", paste(flds, collapse = ",\n\t"), "\n)")
}

#' @export
dbBuildTableDefinition <- function(...) {
  warning_once("RSQLite::dbBuildTableDefinition() is deprecated, please switch to DBI::sqlCreateTable().")
  sqliteBuildTableDefinition(...)
}

#' isIdCurrent
#'
#' Deprecated. Please use dbIsValid instead.
#'
#' @keywords internal
#' @export
isIdCurrent <- function(obj) {
  .Deprecated("dbIsValid")
  dbIsValid(obj)
}

#' Make R/S-Plus identifiers into legal SQL identifiers
#'
#' Deprecated. Please use [dbQuoteIdentifier()] instead.
#'
#' @keywords internal
#' @export
setMethod("make.db.names",
  signature(dbObj="SQLiteConnection", snames = "character"),
  function(dbObj, snames, keywords, unique, allow.keywords, ...) {
    warning_once("RSQLite::make.db.names() is deprecated, please switch to DBI::dbQuoteIdentifier().")
    make.db.names.default(snames, keywords, unique, allow.keywords)
  }
)

#' @export
#' @rdname make.db.names-SQLiteConnection-character-method
setMethod("SQLKeywords", "SQLiteConnection", function(dbObj, ...) {
  .SQL92Keywords
})

#' @export
#' @rdname make.db.names-SQLiteConnection-character-method
setMethod("isSQLKeyword",
  signature(dbObj="SQLiteConnection", name="character"),
  function(dbObj, name, keywords, case, ...) {
    warning_once("RSQLite::isSQLKeyword() is deprecated, please switch to DBI::dbQuoteIdentifier().")
    isSQLKeyword.default(name, keywords = .SQL92Keywords, case)
  }
)

#' Deprecated querying tools
#'
#' These functions have been deprecated. Please switch to using
#' [dbSendQuery()]/[dbGetQuery()] with the `params` argument
#' or with calling [dbBind()] instead.
#'
#' @keywords internal
#' @name query-dep
NULL

#' @rdname query-dep
#' @param bind.data A data frame of data to be bound.
#' @export
setMethod("dbSendPreparedQuery",
  c("SQLiteConnection", "character", "data.frame"),
  function(conn, statement, bind.data, ...) {
    warning_once("RSQLite::dbSendPreparedQuery() is deprecated, please switch to DBI::dbSendQuery(params = bind.data).")

    res <- dbSendQuery(conn, statement)

    tryCatch(
      db_bind(res, unclass(bind.data), allow_named_superset = TRUE),
      error = function(e) {
        db_bind(res, unclass(unname(bind.data)), allow_named_superset = FALSE)
      }
    )
    res
  }
)

#' @rdname query-dep
#' @export
setMethod("dbGetPreparedQuery",
  c("SQLiteConnection", "character", "data.frame"),
  function(conn, statement, bind.data, ...) {
    warning_once("RSQLite::dbGetPreparedQuery() is deprecated, please switch to DBI::dbGetQuery(params = bind.data).")

    res <- dbSendQuery(conn, statement)
    on.exit(dbClearResult(res), add = TRUE)

    bind.data <- as.list(bind.data)

    tryCatch(
      db_bind(res, bind.data, allow_named_superset = TRUE),
      error = function(e) {
        db_bind(res, unname(bind.data), allow_named_superset = FALSE)
      }
    )
    dbFetch(res)
  }
)

#' Return an entire column from a SQLite database
#'
#' A shortcut for
#' \code{\link[DBI]{dbReadTable}(con, table, select.cols = column, row.names = FALSE)[[1]]},
#' kept for compatibility reasons.
#'
#' @keywords internal
#' @export
sqliteQuickColumn <- function(con, table, column) {
  dbGetQuery(con, paste("SELECT ", column, " FROM ", table), row.names = FALSE)[[1]]
}

#' Get metadata about a database object
#'
#' Deprecated. Please use individual functions.
#'
#' @param dbObj An object of class \code{\linkS4class{SQLiteDriver}},
#'   \code{\linkS4class{SQLiteConnection}} or
#'   \code{\linkS4class{SQLiteResult}}
#' @name dbGetInfo
#' @keywords internal
NULL

#' @rdname dbGetInfo
#' @export
setMethod("dbGetInfo", "SQLiteDriver", function(dbObj, ...) {
  warning_once("RSQLite::dbGetInfo() is deprecated: please use individual metadata functions instead")
  list()
})

#' @rdname dbGetInfo
#' @export
setMethod("dbGetInfo", "SQLiteConnection", function(dbObj, ...) {
  warning_once("RSQLite::dbGetInfo() is deprecated: please use individual metadata functions instead")
  list()
})

#' dbListResults
#'
#' DEPRECATED
#'
#' @keywords internal
#' @export
setMethod("dbListResults", "SQLiteConnection", function(conn, ...) {
  warning("Querying the results associated with a connection is no longer supported",
    call. = FALSE)
  if (is.null(conn@ref$result))
    list()
  else
    list(conn@ref$result)
})


#' Fetch
#'
#' A shortcut for \code{\link[DBI]{dbFetch}(res, n = n, row.names = FALSE)},
#' kept for compatibility reasons.
#'
#' @keywords internal
#' @export
setMethod("fetch", "SQLiteResult", function(res, n = -1, ...) {
  dbFetch(res, n = n, row.names = FALSE)
})
