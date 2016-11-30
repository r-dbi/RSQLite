#' @include SQLiteResult.R
NULL

#' Execute a SQL statement on a database connection
#'
#' To retrieve results a chunk at a time, use [dbSendQuery()],
#' [dbFetch()], then [dbClearResult()]. Alternatively, if you want all the
#' results (and they'll fit in memory) use [dbGetQuery()] which sends,
#' fetches and clears for you. To run the same prepared query with multiple
#' inputs, use [dbBind()].
#' For statements that do not return a table,
#' use [dbSendStatement()] and [dbExecute()] instead of [dbSendQuery()]
#' and [dbGetQuery()].
#' See \link{sqlite-meta} for how to extract other metadata from the result set.
#'
#' @seealso
#' The corresponding generic functions
#' [DBI::dbSendQuery()], [DBI::dbFetch()], [DBI::dbClearResult()], [DBI::dbGetQuery()],
#' [DBI::dbBind()], [DBI::dbSendStatement()], and [DBI::dbExecute()].
#'
#' @param conn an \code{\linkS4class{SQLiteConnection}} object.
#' @param statement a character vector of length one specifying the SQL
#'   statement that should be executed.  Only a single SQL statment should be
#'   provided.
#' @param params A named list of query parameters to be substituted into
#'   a parameterised query. The elements of the list can be vectors
#'   which all must be of the same length.
#' @param ... Unused. Needed for compatibility with generic.
#' @examples
#' library(DBI)
#' db <- RSQLite::datasetsDb()
#'
#' # Run query to get results as dataframe
#' dbGetQuery(db, "SELECT * FROM USArrests LIMIT 3")
#'
#' # Send query to pull requests in batches
#' rs <- dbSendQuery(db, "SELECT * FROM USArrests")
#' dbFetch(rs, n = 2)
#' dbFetch(rs, n = 2)
#' dbHasCompleted(rs)
#' dbClearResult(rs)
#'
#' # Parameterised queries are safest when you accept user input
#' dbGetQuery(db, "SELECT * FROM USArrests WHERE Murder < ?", list(3))
#'
#' # Or create and then bind
#' rs <- dbSendQuery(db, "SELECT * FROM USArrests WHERE Murder < ?")
#' dbBind(rs, list(3))
#' dbFetch(rs)
#' dbClearResult(rs)
#'
#' # Named parameters are a little more convenient
#' rs <- dbSendQuery(db, "SELECT * FROM USArrests WHERE Murder < :x")
#' dbBind(rs, list(x = 3))
#' dbFetch(rs)
#' dbClearResult(rs)
#' dbDisconnect(db)
#'
#' # Passing multiple values is especially useful for statements
#' con <- dbConnect(RSQLite::SQLite())
#'
#' dbWriteTable(con, "test", data.frame(a = 1L, b = 2L))
#' dbReadTable(con, "test")
#'
#' dbExecute(con, "INSERT INTO test VALUES (:a, :b)",
#'           params = list(a = 2:4, b = 3:5))
#' dbReadTable(con, "test")
#'
#' rs <- dbSendStatement(con, "DELETE FROM test WHERE a = :a AND b = :b")
#' dbBind(rs, list(a = 3:1, b = 2:4))
#' dbBind(rs, list(a = 4L, b = 5L))
#' dbClearResult(rs)
#' dbReadTable(con, "test")
#'
#' # Multiple values passed to queries are executed one after another,
#' # the result appears as one data frame
#' dbGetQuery(con, "SELECT * FROM TEST WHERE a >= :a", list(a = 0:3))
#'
#' dbDisconnect(con)
#'
#' @name sqlite-query
NULL

#' @rdname sqlite-query
#' @export
setMethod("dbSendQuery", c("SQLiteConnection", "character"),
  function(conn, statement, params = NULL, ...) {
    statement <- enc2utf8(statement)

    if (!is.null(conn@ref$result)) {
      warning("Closing open result set, pending rows", call. = FALSE)
      dbClearResult(conn@ref$result)
      stopifnot(is.null(conn@ref$result))
    }

    rs <- new("SQLiteResult",
      sql = statement,
      ptr = rsqlite_send_query(conn@ptr, statement),
      conn = conn
    )
    on.exit(dbClearResult(rs), add = TRUE)

    if (!is.null(params)) {
      dbBind(rs, params)
    }
    on.exit(NULL, add = FALSE)

    conn@ref$result <- rs
    rs
  }
)


#' @export
DBI::dbGetQuery


#' @rdname sqlite-query
#' @export
setMethod("dbBind", "SQLiteResult", function(res, params, ...) {
  db_bind(res, as.list(params), ..., allow_named_superset = FALSE)
})


db_bind <- function(res, params, ..., allow_named_superset) {
  if (is.null(names(params))) {
    names(params) <- rep("", length(params))
  } else if (allow_named_superset) {
    param_pos <- rsqlite_find_params(res@ptr, names(params))
    if (any(is.na(param_pos))) {
      warning("Named parameters not used in query: ",
              paste0(names(params)[is.na(param_pos)], collapse = ", "),
              call. = FALSE)
      params <- params[!is.na(param_pos)]
    }
  }

  params <- factor_to_string(params)
  params <- string_to_utf8(params)

  rsqlite_bind_rows(res@ptr, params)
  invisible(res)
}


#' @param res an \code{\linkS4class{SQLiteResult}} object.
#' @param n maximum number of records to retrieve per fetch. Use `-1` to
#'    retrieve all pending records; `0` retrieves only the table definition.
#' @inheritParams DBI::sqlColumnToRownames
#' @export
#' @rdname sqlite-query
setMethod("dbFetch", "SQLiteResult", function(res, n = -1, ..., row.names = NA) {
  row.names <- compatRowNames(row.names)
  sqlColumnToRownames(rsqlite_fetch(res@ptr, n = n), row.names)
})

#' @export
#' @rdname sqlite-query
setMethod("dbClearResult", "SQLiteResult", function(res, ...) {
  if (!dbIsValid(res)) {
    stop("Expired, result set already closed", call. = FALSE)
  }
  rsqlite_clear_result(res@ptr)
  res@conn@ref$result <- NULL
  invisible(TRUE)
})

#' Result information
#'
#' For a result object, returns information about the SQL statement used,
#' the available columns and number of already fetched rows for a query,
#' the number of affected rows for a statement,
#' and the completion status.
#'
#' @seealso
#' The corresponding generic functions
#' [DBI::dbColumnInfo()], [DBI::dbGetRowsAffected()], [DBI::dbGetRowCount()],
#' [DBI::dbHasCompleted()], and [DBI::dbGetStatement()].
#'
#' @param res An object of class \code{\linkS4class{SQLiteResult}}
#' @param ... Ignored. Needed for compatibility with generic
#' @examples
#' library(DBI)
#' db <- RSQLite::datasetsDb()
#' rs <- dbSendQuery(db, "SELECT * FROM USArrests WHERE UrbanPop >= 80")
#' dbGetStatement(rs)
#' dbColumnInfo(rs)
#' dbHasCompleted(rs)
#' dbGetRowCount(rs)
#'
#' dbFetch(rs, n = 2)
#' dbHasCompleted(rs)
#' dbGetRowCount(rs)
#'
#' invisible(dbFetch(rs))
#' dbHasCompleted(rs)
#' dbGetRowCount(rs)
#' dbClearResult(rs)
#'
#' dbDisconnect(db)
#'
#' con <- dbConnect(RSQLite::SQLite(), ":memory:")
#' dbExecute(con, "CREATE TABLE test (a INTEGER)")
#' rs <- dbSendStatement(con, "INSERT INTO test VALUES (:a)", list(a = 1:3))
#' dbGetRowsAffected(rs)
#' dbClearResult(rs)
#' dbDisconnect(con)
#' @name sqlite-meta
NULL

#' @export
#' @rdname sqlite-meta
setMethod("dbColumnInfo", "SQLiteResult", function(res, ...) {
  rsqlite_column_info(res@ptr)
})
#' @export
#' @rdname sqlite-meta
setMethod("dbGetRowsAffected", "SQLiteResult", function(res, ...) {
  rsqlite_rows_affected(res@ptr)
})
#' @export
#' @rdname sqlite-meta
setMethod("dbGetRowCount", "SQLiteResult", function(res, ...) {
  rsqlite_row_count(res@ptr)
})
#' @export
#' @rdname sqlite-meta
setMethod("dbHasCompleted", "SQLiteResult", function(res, ...) {
  rsqlite_has_completed(res@ptr)
})
#' @rdname sqlite-meta
#' @export
setMethod("dbGetStatement", "SQLiteResult", function(res, ...) {
  res@sql
})
