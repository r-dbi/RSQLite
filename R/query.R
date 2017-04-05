#' @include SQLiteResult.R
NULL

#' @rdname SQLiteConnection-class
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


#' @rdname SQLiteResult-class
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
              ". Use $", names(params)[is.na(param_pos)][[1]],
              " etc. instead of ? with named lists.",
              call. = FALSE)
      params <- params[!is.na(param_pos)]
    }
  }

  params <- factor_to_string(params)
  params <- string_to_utf8(params)

  rsqlite_bind_rows(res@ptr, params)
  invisible(res)
}


#' @export
#' @rdname SQLiteResult-class
setMethod("dbFetch", "SQLiteResult", function(res, n = -1, ..., row.names = NA) {
  row.names <- compatRowNames(row.names)
  if (n < -1) stop("n must be nonnegative or -1 in dbFetch()", call. = FALSE)
  if (is.infinite(n)) n <- -1
  sqlColumnToRownames(rsqlite_fetch(res@ptr, n = n), row.names)
})

#' @export
#' @rdname SQLiteResult-class
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
