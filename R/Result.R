#' Class SQLiteResult
#' 
#' SQLite's query results class.  This classes encapsulates the result of an
#' SQL statement (either \code{select} or not).
#' 
#' @export
#' @keywords internal
setClass("SQLiteResult", 
  contains = "DBIResult",
  slots = list(
    sql = "character",
    ptr = "externalptr"
  )
)

#' @rdname SQLiteResult-class
#' @export
setMethod("show", "SQLiteResult", function(object) {
  cat("<SQLiteResult>\n")
  if(!dbIsValid(object)){
    cat("EXPIRED\n")
  } else {  
    cat("  SQL  ", dbGetStatement(object), "\n", sep = "")
    
    done <- if (dbHasCompleted(object)) "complete" else "incomplete"
    cat("  ROWS Fetched: ", dbGetRowCount(object), " [", done, "]\n", sep = "")
    cat("       Changed: ", dbGetRowsAffected(object), "\n", sep = "")
  }
  invisible(NULL)  
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
#' db <- RSQLite::datasetsDb()
#' 
#' # Run query to get results as dataframe
#' dbGetQuery(db, "SELECT * FROM USArrests LIMIT 3")
#'
#' # Send query to pull requests in batches
#' res <- dbSendQuery(con, "SELECT * FROM USArrests")
#' fetch(res, n = 2)
#' fetch(res, n = 2)
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
#' dbDisconnect(db)
#' @name query
NULL

#' @rdname query
#' @export
setMethod("dbSendQuery", c("SQLiteConnection", "character"),
  function(conn, statement, params = NULL, ...) {
    rs <- new("SQLiteResult", 
      sql = statement,
      ptr = rsqlite_send_query(conn@ptr, statement)
    )
    
    if (!is.null(params)) {
      dbBind(rs, params)
    }
    
    rs
  }
)

#' @rdname query
#' @export
setMethod("dbGetQuery", signature("SQLiteConnection", "character"), 
  function(conn, statement, ...) {
    rs <- dbSendQuery(conn, statement, ...)
    on.exit(dbClearResult(rs))
    
    dbFetch(rs, n = -1, ...)
  }
)

#' @rdname query
#' @export
setMethod("dbBind", "SQLiteResult", function(res, params, ...) {
  if (is.null(names(params))) {
    names(params) <- rep("", length(params))
  }
  
  rsqlite_bind_params(res@ptr, params)
  invisible(res)
})


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
setMethod("dbListResults", "SQLiteConnection", function(conn, ...) {
  stop("Querying the results associated with a connection is no longer supported", 
    call. = FALSE)
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
