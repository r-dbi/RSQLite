#' @include Object.R
NULL

#' @export
setClass("SQLiteResult", representation("DBIResult", "SQLiteObject"))

setAs("SQLiteResult", "SQLiteConnection",
  def = function(from) new("SQLiteConnection", Id = from@Id)
)
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
