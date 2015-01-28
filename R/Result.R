#' Class SQLiteResult
#' 
#' SQLite's query results class.  This classes encapsulates the result of an
#' SQL statement (either \code{select} or not).
#' 
#' @export
#' @keywords internal
setClass("SQLiteResult", 
  contains = "DBIResult",
  slots = list(ptr = "externalptr")
)

#' @rdname SQLiteResult-class
#' @export
setMethod("show", "SQLiteResult", function(object) {
  cat("<SQLiteResult>\n")
})

#' Execute a SQL statement on a database connection
#' 
#' To retrieve results a chunk at a time, use \code{dbSendQuery}, 
#' \code{dbFetch}, then \code{ClearResult}. Alternatively, if you want all the 
#' results (and they'll fit in memory) use \code{dbGetQuery} which sends, 
#' fetches and clears for you.
#' 
#' @param conn an \code{\linkS4class{SQLiteConnection}} object.
#' @param statement a character vector of length one specifying the SQL
#'   statement that should be executed.  Only a single SQL statment should be
#'   provided.
#' @param ... Unused. Needed for compatibility with generic.
#' @examples
#' con <- dbConnect(SQLite(), ":memory:")
#' dbWriteTable(con, "arrests", datasets::USArrests)
#' 
#' # Run query to get results as dataframe
#' dbGetQuery(con, "SELECT * FROM arrests limit 3")
#'
#' # Send query to pull requests in batches
#' res <- dbSendQuery(con, "SELECT * FROM arrests")
#' data <- fetch(res, n = 2)
#' data
#' dbHasCompleted(res)
#' 
#' dbListResults(con)
#' dbClearResult(res)
#' 
#' # Use dbSendPreparedQuery/dbGetPreparedQuery for "prepared" queries
#' dbGetPreparedQuery(con, "SELECT * FROM arrests WHERE Murder < ?", 
#'    data.frame(x = 3))
#' dbGetPreparedQuery(con, "SELECT * FROM arrests WHERE Murder < (:x)", 
#'    data.frame(x = 3))
#' 
#' dbDisconnect(con)
#' @name query
NULL

#' @rdname query
#' @export
setMethod("dbSendQuery", c("SQLiteConnection", "character"),
  function(conn, statement) {
    new("SQLiteResult", ptr = rsqlite_send_query(conn@ptr, statement))
  }
)

#' @rdname query
#' @param bind.data A data frame of data to be bound.
#' @export
setMethod("dbSendPreparedQuery", 
  c("SQLiteConnection", "character", "data.frame"),
  function(conn, statement, bind.data) {
    sqliteSendQuery(conn, statement, bind.data)
  }
)

#' @useDynLib RSQLite rsqlite_query_send
sqliteSendQuery <- function(con, statement, bind.data = NULL) {
  if (!is.null(bind.data)) {
    if (!is.data.frame(bind.data)) {
      bind.data <- as.data.frame(bind.data)
    }
    if (nrow(bind.data) == 0 || ncol(bind.data) == 0) {
      stop("bind.data must have non-zero dimensions")
    }
  }
  
  rsId <- .Call(rsqlite_query_send, con@Id, as.character(statement), bind.data)
  new("SQLiteResult", Id = rsId)
}


#' @param res an \code{\linkS4class{SQLiteResult}} object.
#' @param n maximum number of records to retrieve per fetch. Use \code{-1} to 
#'    retrieve all pending records; use \code{0} for to fetch the default 
#'    number of rows as defined in \code{\link{SQLite}}
#' @export
#' @rdname query
setMethod("dbFetch", "SQLiteResult", function(res, n = -1, ...) {
  rsqlite_fetch(res@ptr, n = n)
})

#' @rdname query
#' @rdname dbFetch-SQLiteResult-method
setMethod("fetch", "SQLiteResult", function(res, n = -1, ...) {
  rsqlite_fetch(res@ptr, n = n)
})

#' @export
#' @rdname query
setMethod("dbClearResult", "SQLiteResult", function(res, ...) {
  rsqlite_clear_result(res@ptr)
  invisible(TRUE)
})

#' @export
#' @rdname query
#' @useDynLib RSQLite rsqlite_result_free_handle
setMethod("dbListResults", "SQLiteConnection", function(conn, ...) {
  stop("Querying the results associated with a connection is no longer supported", 
    call. = FALSE)
})

#' @rdname query
#' @export
setMethod("dbGetPreparedQuery", 
  c("SQLiteConnection", "character", "data.frame"),
  function(conn, statement, bind.data) {
    sqliteGetQuery(conn, statement, bind.data)
  }
)

sqliteGetQuery <- function(con, statement, bind.data = NULL) {
  rs <- sqliteSendQuery(con, statement, bind.data)
  on.exit(dbClearResult(rs))
  
  if (dbHasCompleted(rs)) {
    return(invisible())
  }
  
  res <- sqliteFetch(rs, n = -1)
  if (!dbHasCompleted(rs)) {
    warning("Pending rows")
  }
  
  res
}


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
#' fetch(rs, n=2)
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
  dbGetInfo(res)$fields
})
#' @export
#' @rdname sqlite-meta
setMethod("dbGetRowsAffected", "SQLiteResult", function(res, ...) {
  dbGetInfo(res)$rowsAffected
})
#' @export
#' @rdname sqlite-meta
setMethod("dbGetRowCount", "SQLiteResult", function(res, ...) {
  dbGetInfo(res)$rowCount
})
#' @export
#' @rdname sqlite-meta
setMethod("dbHasCompleted", "SQLiteResult", function(res, ...) {
  rsqlite_has_completed(res@ptr)
})
#' @rdname sqlite-meta
#' @export
setMethod("dbGetStatement", "SQLiteResult", function(res, ...) {
  dbGetInfo(res)$statement
})
