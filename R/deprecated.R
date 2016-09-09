#' @include SQLiteConnection.R
NULL

#' Generics for getting and sending prepared queries.
#'
#' @param conn An \code{DBIConnection} object.
#' @param statement A SQL string
#' @param bind.data A data frame
#' @param ... Other arguments used by methods
#' @export
setGeneric("dbSendPreparedQuery", function(conn, statement, bind.data, ...) {
  standardGeneric("dbSendPreparedQuery")
})

#' @rdname dbSendPreparedQuery
#' @export
setGeneric("dbGetPreparedQuery", function(conn, statement, bind.data, ...) {
  standardGeneric("dbGetPreparedQuery")
})

#' Generic for creating a new transaction.
#'
#' See method documentation for details.
#'
#' @export
#' @param conn An \code{DBIConnection} object.
#' @param ... Other arguments used by methods
#' @keywords internal
setGeneric("dbBeginTransaction", function(conn, ...) {
  .Deprecated("dbBegin", old = "dbBeginTransaction")
  dbBegin(conn, ...)
})

#' Build the SQL CREATE TABLE definition as a string
#'
#' The output SQL statement is a simple \code{CREATE TABLE} with suitable for
#' \code{dbGetQuery}
#'
#' @param conn A database connection.
#' @param name Name of the new SQL table
#' @param value A data.frame, for which we want to create a table.
#' @param field.types Optional, named character vector of the types for each
#'   field in \code{value}
#' @param row.names Logical. Should row.name of \code{value} be exported as a
#'   \code{row\_names} field? Default is \code{TRUE}
#' @return An SQL string
#' @keywords internal
#' @aliases dbBuildTableDefinition
#' @export
sqliteBuildTableDefinition <- function(con, name, value, field.types = NULL,
  row.names = NA) {

  warning("Deprecated: please use DBI::sqlCreateTable instead")
  row.names <- compatRowNames(row.names)

  sqliteBuildTableDefinitionNoWarn(con, name, value, field.types, row.names)
}

sqliteBuildTableDefinitionNoWarn <- function(con, name, value, field.types = NULL,
                                             row.names = NA) {
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
  .Deprecated("sqliteBuildTableDefinition")
  sqliteBuildTableDefinition(...)
}

#' isIdCurrent.
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
#' Deprecated. Please use \code{dbQuoteIdentifier} instead.
#'
#' @keywords internal
#' @export
setMethod("make.db.names",
  signature(dbObj="SQLiteConnection", snames = "character"),
  function(dbObj, snames, keywords, unique, allow.keywords, ...) {
    .Deprecated("dbQuoteIdentifier", old = "make.db.names")
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
    .Deprecated("dbQuoteIdentifier", old = "isSQLKeyword")
    isSQLKeyword.default(name, keywords = .SQL92Keywords, case)
  }
)

#' Deprecated querying tools
#'
#' These functions have been deprecated. Please switch to using
#' \code{dbSendQuery}/\code{dbGetQuery} + \code{dbBind} instead.
#'
#' @keywords internal
#' @name query-dep
NULL

#' @rdname query-dep
#' @param bind.data A data frame of data to be bound.
#' @export
setMethod("dbSendPreparedQuery",
  c("SQLiteConnection", "character", "data.frame"),
  function(conn, statement, bind.data) {
    .Deprecated("dbBind", old = "dbSendPreparedQuery")

    res <- dbSendQuery(conn, statement)

    bind_data_rows <- by(bind.data, seq_len(nrow(bind.data)), identity, simplify = FALSE)

    lapply(
      bind_data_rows,
      function(row) {
        tryCatch(
          dbBind(res, unclass(row)),
          error = function(e) {
            dbBind(res, unclass(unname(row)))
          }
        )
        dbFetch(res)
        NULL
      }
    )

    res
  }
)

#' @rdname query-dep
#' @export
setMethod("dbGetPreparedQuery",
  c("SQLiteConnection", "character", "data.frame"),
  function(conn, statement, bind.data) {
    .Deprecated("dbBind", old = "dbGetPreparedQuery")

    res <- dbSendQuery(conn, statement)
    on.exit(dbClearResult(res), add = TRUE)

    bind_data_rows <- by(bind.data, seq_len(nrow(bind.data)), identity, simplify = FALSE)

    results <- lapply(
      bind_data_rows,
      function(row) {
        tryCatch(
          dbBind(res, unclass(row)),
          error = function(e) {
            dbBind(res, unclass(unname(row)))
          }
        )
        dbFetch(res)
      }
    )

    do.call(rbind, results)
  }
)

#' Return an entire column from a SQLite database
#'
#' DEPRECATED. Please use dbReadTable instead.
#'
#' @keywords internal
#' @export
sqliteQuickColumn <- function(con, table, column) {
  warning("Deprecated. Please use dbReadTable instead.")
  dbReadTable(con, table, select.cols = column, row.names = FALSE)[[1]]
}

#' Get metadata about a database object.
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
setMethod("dbGetInfo", "SQLiteDriver", function(dbObj) {
  warning("dbGetInfo is deprecated: please use individual metadata functions instead",
    call. = FALSE)

  list()
})

#' @rdname dbGetInfo
#' @export
setMethod("dbGetInfo", "SQLiteConnection", function(dbObj) {
  warning("dbGetInfo is deprecated: please use individual metadata functions instead",
    call. = FALSE)

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


#' Fetch.
#'
#' Deprecated. Please use \code{dbFetch} instead.
#'
#' @keywords internal
#' @export
setMethod("fetch", "SQLiteResult", function(res, n = -1, ..., row.names = NA) {
  row.names <- compatRowNames(row.names)
  sqlColumnToRownames(rsqlite_fetch(res@ptr, n = n), row.names)
})

