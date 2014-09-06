#' Class SQLiteResult
#' 
#' SQLite's query results class.  This classes encapsulates the result of an
#' SQL statement (either \code{select} or not).
#' 
#' @export
setClass("SQLiteResult", 
  contains = "DBIResult",
  slots = list(Id = "externalptr")
)

#' Fetch records from a previously executed query
#' 
#' The \code{RSQLite} implementations retrieves all records into a buffer
#' internally managed by the RSQLite driver (thus this memory in not managed by
#' R but its part of the R process), and \code{fetch} simply returns records
#' from this internal buffer.
#' 
#' @param res an \code{\linkS4class{SQLiteResult}} object.
#' @param n maximum number of records to retrieve per fetch. Use \code{-1} to 
#'    retrieve all pending records; use \code{0} for to fetch the default 
#'    number of rows as defined in \code{\link{SQLite}}
#' @examples
#' con <- dbConnect(SQLite())
#' dbWriteTable(con, "jratings", datasets::USJudgeRatings)
#' 
#' res <- dbSendQuery(con, "SELECT row_names, ORAL, DILG, FAMI FROM jratings")
#' 
#' # we now fetch the first 10 records from the resultSet into a data.frame
#' data1 <- dbFetch(res, n = 10)   
#' dim(data1)
#' 
#' dbHasCompleted(res)
#' 
#' # let's get all remaining records
#' data2 <- dbFetch(res, n = -1)
#' dbClearResult(res)
#' dbDisconnect(con)
#' @export
setMethod("dbFetch", "SQLiteResult", function(res, n = 0) {
  sqliteFetch(res, n = n)
})

#' @export
#' @rdname dbFetch-SQLiteResult-method
setMethod("fetch", "SQLiteResult", function(res, n = 0) {
  sqliteFetch(res, n = n)
})

#' @useDynLib RSQLite RS_SQLite_fetch
sqliteFetch <- function(res, n = 0) {  
  check_valid(res)

  # Returns NULL, or a list
  rel <- .Call(RS_SQLite_fetch, res@Id, nrec = as.integer(n))
  if (is.null(rel)) return(data.frame())
  
  attr(rel, "row.names") <- .set_row_names(length(rel[[1]]))
  attr(rel, "class") <- "data.frame"
  rel
}

#' Clear a result set.
#' 
#' @export
#' @param res an \code{\linkS4class{SQLiteResult}} object.
#' @param ... Ignored. Needed for compatibility with generic.
#' @useDynLib RSQLite RS_SQLite_closeResultSet
setMethod("dbClearResult", "SQLiteResult", function(res, ...) {
  if (!isIdCurrent(res)){
    warning("Expired SQLiteResult", call. = FALSE)
    return(TRUE)
  }
  .Call(RS_SQLite_closeResultSet, res@Id)
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
  out <- dbGetInfo(res)$completed
  if(out < 0) NA else out == 1L
})
