#' @include Object.R
NULL

#' Class SQLiteResult
#' 
#' SQLite's query results class.  This classes encapsulates the result of an
#' SQL statement (either \code{select} or not).
#' 
#' 
#' @name SQLiteResult-class
#' @docType class
#' @section Generators: The main generator is \code{\link[DBI]{dbSendQuery}}.
#' @export
setClass("SQLiteResult", representation("DBIResult", "SQLiteObject"))

setAs("SQLiteResult", "SQLiteConnection",
  def = function(from) new("SQLiteConnection", Id = from@Id)
)


#' Fetch records from a previously executed query
#' 
#' This method is a straight-forward implementation of the corresponding
#' generic function.
#' 
#' The \code{RSQLite} implementations retrieves all records into a buffer
#' internally managed by the RSQLite driver (thus this memory in not managed by
#' R but its part of the R process), and \code{fetch} simple returns records
#' from this internal buffer.
#' 
#' @name fetch-methods
#' @aliases fetch-methods fetch,SQLiteResult,numeric-method
#' fetch,SQLiteResult-method
#' @docType methods
#' @section Methods: \describe{
#' 
#' \item{res}{ an \code{SQLiteResult} object.  } \item{n}{ maximum number of
#' records to retrieve per fetch.  Use \code{n = -1} to retrieve all pending
#' records; use a value of \code{n = 0} for fetching the default number of rows
#' \code{fetch.default.rec} defined in the \code{\link{SQLite}} initialization
#' invocation.  } \item{list()}{currently not used.}\item{ }{currently not
#' used.} }
#' @examples
#' 
#' drv <- dbDriver("SQLite")
#' tfile <- tempfile()
#' con <- dbConnect(drv, dbname = tfile)
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
#' 
#' dbClearResult(res)
#' dbDisconnect(con)
#' 
NULL
#' @export
setMethod("fetch", "SQLiteResult",
  definition = function(res, n = 0, ...) sqliteFetch(res, n = n, ...),
  valueClass = "data.frame"
)

## Fetch at most n records from the opened resultSet (n = -1 meanSQLite
## all records, n=0 means extract as many as "default_fetch_rec",
## as defined by SQLiteDriver (see summary(drv, TRUE)).
## The returned object is a data.frame.
## Note: The method dbHasCompleted() on the resultSet tells you whether
## or not there are pending records to be fetched.
##
## TODO: Make sure we don't exhaust all the memory, or generate
## an object whose size exceeds option("object.size").  Also,
## are we sure we want to return a data.frame?
#' @export
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

#' @export
setMethod("dbClearResult", "SQLiteResult",
  definition = function(res, ...) sqliteCloseResult(res, ...),
  valueClass = "logical"
)
#' @export
sqliteCloseResult <- function(res, ...) {
  if(!isIdCurrent(res)){
    warning(paste("expired SQLiteResult"))
    return(TRUE)
  }
  .Call("RS_SQLite_closeResultSet", res@Id, PACKAGE = .SQLitePkgName)
}


#' Database interface meta-data
#' 
#' These methods are straight-forward implementations of the corresponding
#' generic functions.
#' 
#' 
#' @name dbGetInfo-methods
#' @aliases dbGetInfo dbGetDBIVersion-methods dbGetStatement-methods
#' dbGetRowCount-methods dbGetRowsAffected-methods dbColumnInfo-methods
#' dbHasCompleted-methods dbGetInfo,SQLiteObject-method
#' dbGetInfo,SQLiteDriver-method dbGetInfo,SQLiteConnection-method
#' dbGetInfo,SQLiteResult-method dbGetStatement,SQLiteResult-method
#' dbGetRowCount,SQLiteResult-method dbGetRowsAffected,SQLiteResult-method
#' dbColumnInfo,SQLiteResult-method dbHasCompleted,SQLiteResult-method
#' @docType methods
#' @section Methods: \describe{ \item{dbObj}{ any object that implements some
#' functionality in the R/S-Plus interface to databases (a driver, a connection
#' or a result set).  } %\item{drv}{an \code{SQLiteDriver}.} %\item{conn}{an
#' \code{SQLiteConnection}.} \item{res}{ an \code{SQLiteResult}.}
#' \item{list()}{currently not being used.} }
#' @examples
#' 
#' data(USArrests)
#' drv <- dbDriver("SQLite")
#' con <- dbConnect(drv, dbname=":memory:")
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
#' 
NULL

#' @export
setMethod("dbGetInfo", "SQLiteResult",
  definition = function(dbObj, ...) sqliteResultInfo(dbObj, ...),
  valueClass = "list"
)
#' @export
setMethod("dbGetStatement", "SQLiteResult",
  definition = function(res, ...) dbGetInfo(res, "statement")[[1]],
  valueClass = "character"
)
#' @export
setMethod("dbColumnInfo", "SQLiteResult",
  definition = function(res, ...){
    out <- dbGetInfo(res, "fields")[[1]]
    if(!is.null(out)) out else data.frame(out)
  },
  valueClass = "data.frame"
)
#' @export
setMethod("dbGetRowsAffected", "SQLiteResult",
  definition = function(res, ...) dbGetInfo(res, "rowsAffected")[[1]],
  valueClass = "integer"
)
#' @export
setMethod("dbGetRowCount", "SQLiteResult",
  definition = function(res, ...) dbGetInfo(res, "rowCount")[[1]],
  valueClass = "integer"
)
#' @export
setMethod("dbHasCompleted", "SQLiteResult",
  definition = function(res, ...){
    out <- dbGetInfo(res, "completed")[[1]]
    if(out<0)
      NA
    else out == 1L
  },
  valueClass = "logical"
)

#' @export
setMethod("summary", "SQLiteResult",
  definition = function(object, ...) sqliteDescribeResult(object, ...)
)
#' @export
sqliteDescribeResult <- function(obj, verbose = FALSE, ...) {
  if(!isIdCurrent(obj)){
    show(obj)
    invisible(return(NULL))
  }
  show(obj)
  cat("  Statement:", dbGetStatement(obj), "\n")
  cat("  Has completed?", if(dbHasCompleted(obj)) "yes" else "no", "\n")
  cat("  Affected rows:", dbGetRowsAffected(obj), "\n")
  hasOutput <- as.logical(dbGetInfo(obj, "isSelect")[[1]])
  flds <- dbColumnInfo(obj)
  if(hasOutput){
    cat("  Output fields:", nrow(flds), "\n")
    if(verbose && length(flds)>0){
      cat("  Fields:\n")
      out <- print(flds)
    }
  }
  invisible(NULL)
}
