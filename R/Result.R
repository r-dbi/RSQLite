#' @include Object.R
NULL

#' Class SQLiteResult
#' 
#' SQLite's query results class.  This classes encapsulates the result of an
#' SQL statement (either \code{select} or not).
#' 
#' @export
setClass("SQLiteResult", representation("DBIResult", "SQLiteObject"))

setAs("SQLiteResult", "SQLiteConnection",
  def = function(from) new("SQLiteConnection", Id = from@Id)
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
#' @param ... Ignored. Needed for compatibility with generic.
#' @examples
#' con <- dbConnect(SQLite(), dbname = tempfile())
#' data(USJudgeRatings)
#' dbWriteTable(con, "jratings", USJudgeRatings)
#' 
#' res <- dbSendQuery(con, statement = paste(
#'                       "SELECT row_names, ORAL, DILG, FAMI",
#'                       "FROM jratings"))
#' 
#' # we now fetch the first 10 records from the resultSet into a data.frame
#' data1 <- fetch(res, n = 10)   
#' dim(data1)
#' 
#' dbHasCompleted(res)
#' 
#' # let's get all remaining records
#' data2 <- fetch(res, n = -1)
#' @export
setMethod("fetch", "SQLiteResult",
  definition = function(res, n = 0, ...) sqliteFetch(res, n = n, ...),
  valueClass = "data.frame"
)

#' @export
#' @rdname fetch-SQLiteResult-method
sqliteFetch <- function(res, n=0, ...) {  
  if(!isIdCurrent(res))
    stop("invalid result handle")
  n <- as.integer(n)
  rsId <- res@Id
  rel <- .Call("RS_SQLite_fetch", rsId, nrec = n, PACKAGE = .SQLitePkgName)
  if (is.null(rel)) rel <- list()       # result set is completed
  ## create running row index as of previous fetch (if any)
  cnt <- dbGetRowCount(res)
  nrec <- if (length(rel) > 0L) length(rel[[1L]]) else 0L
  indx <- seq(from = cnt - nrec + 1L, length.out = nrec)
  attr(rel, "row.names") <- as.integer(indx)
  class(rel) <- "data.frame"
  rel
}

#' Clear a result set.
#' 
#' @export
#' @param res an \code{\linkS4class{SQLiteResult}} object.
#' @param ... Ignored. Needed for compatibility with generic.
setMethod("dbClearResult", "SQLiteResult",
  definition = function(res, ...) sqliteCloseResult(res, ...),
  valueClass = "logical"
)
#' @export
#' @rdname dbClearResult-SQLiteResult-method
sqliteCloseResult <- function(res, ...) {
  if(!isIdCurrent(res)){
    warning(paste("expired SQLiteResult"))
    return(TRUE)
  }
  .Call("RS_SQLite_closeResultSet", res@Id, PACKAGE = .SQLitePkgName)
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
#' names(dbGetInfo(drv))  
#' 
#' # DBIConnection info
#' names(dbGetInfo(con))
#' 
#' dbDisconnect(con)
#' @name sqlite-meta
NULL

#' @export
#' @rdname sqlite-meta
setMethod("dbColumnInfo", "SQLiteResult",
  definition = function(res, ...){
    out <- dbGetInfo(res, "fields")[[1]]
    if(!is.null(out)) out else data.frame(out)
  },
  valueClass = "data.frame"
)
#' @export
#' @rdname sqlite-meta
setMethod("dbGetRowsAffected", "SQLiteResult",
  definition = function(res, ...) dbGetInfo(res, "rowsAffected")[[1]],
  valueClass = "integer"
)
#' @export
#' @rdname sqlite-meta
setMethod("dbGetRowCount", "SQLiteResult",
  definition = function(res, ...) dbGetInfo(res, "rowCount")[[1]],
  valueClass = "integer"
)
#' @export
#' @rdname sqlite-meta
setMethod("dbHasCompleted", "SQLiteResult",
  definition = function(res, ...){
    out <- dbGetInfo(res, "completed")[[1]]
    if(out<0)
      NA
    else out == 1L
  },
  valueClass = "logical"
)
