#' @include SQLiteResult.R
NULL

#' Execute a SQL statement on a database connection
#'
#' To retrieve results a chunk at a time, use \code{dbSendQuery},
#' \code{dbFetch}, then \code{dbClearResult}. Alternatively, if you want all the
#' results (and they'll fit in memory) use \code{dbGetQuery} which sends,
#' fetches and clears for you. To run the same prepared query with multiple
#' inputs, use \code{dbBind}.
#'
#' See \link{sqlite-meta} for how to extract other metadata from the result set.
#'
#' @param conn an \code{\linkS4class{SQLiteConnection}} object.
#' @param statement a character vector of length one specifying the SQL
#'   statement that should be executed.  Only a single SQL statment should be
#'   provided.
#' @param params A named list of query parameters to be substituted into
#'   a parameterised query.
#' @param ... Unused. Needed for compatibility with generic.
#' @examples
#' library(DBI)
#' db <- RSQLite::datasetsDb()
#'
#' # Run query to get results as dataframe
#' dbGetQuery(db, "SELECT * FROM USArrests LIMIT 3")
#'
#' # Send query to pull requests in batches
#' res <- dbSendQuery(db, "SELECT * FROM USArrests")
#' dbFetch(res, n = 2)
#' dbFetch(res, n = 2)
#' dbHasCompleted(res)
#' dbClearResult(res)
#'
#' # Parameterised queries are safest when you accept user input
#' dbGetQuery(db, "SELECT * FROM USArrests WHERE Murder < ?", list(3))
#'
#' # Or create and then bind
#' rs <- dbSendQuery(db, "SELECT * FROM USArrests WHERE Murder < ?")
#' dbBind(rs, list(3))
#' dbFetch(rs)
#'
#' # Named parameters are a little more convenient
#' rs <- dbSendQuery(db, "SELECT * FROM USArrests WHERE Murder < :x")
#' dbBind(rs, list(x = 3))
#' dbFetch(rs)
#'
#' dbDisconnect(db)
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
#' @param n maximum number of records to retrieve per fetch. Use \code{-1} to
#'    retrieve all pending records; use \code{0} for to fetch the default
#'    number of rows as defined in \code{\link{SQLite}}
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

#' Database interface meta-data.
#'
#' See documentation of generics for more details.
#'
#' @param res An object of class \code{\linkS4class{SQLiteResult}}
#' @param ... Ignored. Needed for compatibility with generic
#' @examples
#' data(USArrests)
#' con <- dbConnect(SQLite(), dbname=":memory:")
#' dbWriteTable(con, "t1", USArrests)
#' dbWriteTable(con, "t2", USArrests)
#'
#' dbListTables(con)
#'
#' rs <- dbSendQuery(con, "select * from t1 where UrbanPop >= 80")
#' dbGetStatement(rs)
#' dbHasCompleted(rs)
#'
#' info <- dbGetInfo(rs)
#' names(info)
#' info$fields
#'
#' dbFetch(rs, n=2)
#' dbHasCompleted(rs)
#' info <- dbGetInfo(rs)
#' info$fields
#' dbClearResult(rs)
#'
#' # DBIConnection info
#' names(dbGetInfo(con))
#'
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
