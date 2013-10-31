#' @include Object.R
NULL

#' Class SQLiteConnection
#' 
#' SQLite connection class.
#' 
#' 
#' @name SQLiteConnection-class
#' @docType class
#' @section Generators: The method \code{\link[DBI]{dbConnect}} is the main
#' generator.
#' @examples
#' 
#' drv <- dbDriver("SQLite")
#' tfile <- tempfile()
#' con <- dbConnect(drv, dbname = tfile)
#' dbDisconnect(con)
#' dbUnloadDriver(drv)
#' 
#' @export
setClass("SQLiteConnection", representation("DBIConnection", "SQLiteObject"))

setAs("SQLiteConnection", "SQLiteDriver",
  def = function(from) new("SQLiteDriver", Id = from@Id)
)

#' Create a connection object to an SQLite DBMS
#' 
#' These methods are straight-forward implementations of the corresponding
#' generic functions.
#' 
#' @name dbConnect-methods
#' @aliases dbDisconnect,SQLiteConnection-method dbConnect,SQLiteDriver-method
#' dbConnect,SQLiteConnection-method dbConnect,character-method
#' @docType methods
#' @section Methods: \describe{ \item{drv}{ an object of class
#' \code{SQLiteDriver}, or the character string "SQLite" or an
#' \code{SQLiteConnection}.  } \item{conn}{ an \code{SQLiteConnection} object
#' as produced by \code{dbConnect}.  } \item{list()}{ As of RSQLite 0.4-1 you
#' may specify values for the two \code{PRAGMAs} \code{cache\_size} and
#' \code{synchronous} when initializing a new connection (this does not apply
#' when cloning an existing connection).
#' 
#' RSQLite defaults \code{synchronous} to 0 (or "OFF"), although SQLite's
#' default as of 3.2.8 is 2 (FULL).  Possible values for \code{synchronous} are
#' 0, 1, or 2 or the corresponding strings "OFF", "NORMAL", or "FULL".  Users
#' have reported significant speed ups using \code{sychronous=0}, and the
#' SQLite documentation itself implies considerable improved performance at the
#' very modest risk of database corruption in the unlikely case of the
#' operating system (\emph{not} the R application) crashing. See the SQLite
#' documentation for the full details of this \code{PRAGMA}.
#' 
#' \code{cache\_size} can be a positive integer to change the maximum number of
#' disk pages that SQLite holds in memory (SQLite's default is 2000 pages).
#' }\item{ }{ As of RSQLite 0.4-1 you may specify values for the two
#' \code{PRAGMAs} \code{cache\_size} and \code{synchronous} when initializing a
#' new connection (this does not apply when cloning an existing connection).
#' 
#' RSQLite defaults \code{synchronous} to 0 (or "OFF"), although SQLite's
#' default as of 3.2.8 is 2 (FULL).  Possible values for \code{synchronous} are
#' 0, 1, or 2 or the corresponding strings "OFF", "NORMAL", or "FULL".  Users
#' have reported significant speed ups using \code{sychronous=0}, and the
#' SQLite documentation itself implies considerable improved performance at the
#' very modest risk of database corruption in the unlikely case of the
#' operating system (\emph{not} the R application) crashing. See the SQLite
#' documentation for the full details of this \code{PRAGMA}.
#' 
#' \code{cache\_size} can be a positive integer to change the maximum number of
#' disk pages that SQLite holds in memory (SQLite's default is 2000 pages). } }
NULL

#' @export
setMethod("dbConnect", "SQLiteDriver",
  definition = function(drv, ...) sqliteNewConnection(drv, ...),
  valueClass = "SQLiteConnection"
)
## note that dbname may be a database name, an empty string "", or NULL.
## The distinction between "" and NULL is that "" is interpreted by
## the SQLite API as the default database (SQLite config specific)
## while NULL means "no database".
#' @export
sqliteNewConnection <- function(drv, dbname = "", loadable.extensions = TRUE,
  cache_size = NULL, synchronous = 0, 
  flags = NULL, vfs = NULL) {
  if (is.null(dbname))
    dbname <- ""
  ## path.expand converts as.character(NA) => "NA"
  if (any(is.na(dbname)))
    stop("'dbname' must not be NA")
  dbname <- path.expand(dbname)
  loadable.extensions <- as.logical(loadable.extensions)
  if (!is.null(vfs)) {
    if (.Platform[["OS.type"]] == "windows") {
      warning("vfs customization not available on this platform.",
        " Ignoring value: vfs = ", vfs)
    } else {
      if (length(vfs) != 1L)
        stop("'vfs' must be NULL or a character vector of length one")
      allowed <- c("unix-posix", "unix-afp", "unix-flock", "unix-dotfile",
        "unix-none")
      if (!(vfs %in% allowed)) {
        stop("'vfs' must be one of ",
          paste(allowed, collapse=", "),
          ". See http://www.sqlite.org/compile.html")
      }
    }
  }
  flags <- if (is.null(flags)) SQLITE_RWC else flags
  drvId <- drv@Id
  conId <- .Call("RS_SQLite_newConnection", drvId,
    dbname, loadable.extensions, flags, vfs, PACKAGE ="RSQLite")
  con <- new("SQLiteConnection", Id = conId)
  
  ## experimental PRAGMAs
  try({
    if(!is.null(cache_size))
      dbGetQuery(con, sprintf("PRAGMA cache_size=%d", as.integer(cache_size)))
    if(is.numeric(synchronous))
      nsync <- as.integer(synchronous)
    else if(is.character(synchronous))
      nsync <-
      pmatch(tolower(synchronous), c("off", "normal", "full"), nomatch = 1) - 1
    else nsync <- 0
    dbGetQuery(con, sprintf("PRAGMA synchronous=%d", as.integer(nsync)))
  }, silent = TRUE)
  
  con
}


#' @export
setMethod("dbConnect", "character",
  definition = function(drv, ...){
    d <- dbDriver(drv)
    dbConnect(d, ...)
  },
  valueClass = "SQLiteConnection"
)
#' @export
setMethod("dbConnect", "SQLiteConnection",
  definition = function(drv, ...){
    new.id <- .Call("RS_SQLite_cloneConnection", drv@Id, PACKAGE = .SQLitePkgName)
    new("SQLiteConnection", Id = new.id)
  },
  valueClass = "SQLiteConnection"
)
#' @export
setMethod("dbDisconnect", "SQLiteConnection",
  definition = function(conn, ...) sqliteCloseConnection(conn, ...),
  valueClass = "logical"
)
#' @export
sqliteCloseConnection <- function(con, ...) {
  if(!isIdCurrent(con)){
    warning(paste("expired SQLiteConnection"))
    return(TRUE)
  }
  .Call("RS_SQLite_closeConnection", con@Id, PACKAGE = .SQLitePkgName)
}


#' @export
setMethod("dbGetInfo", "SQLiteConnection",
  definition = function(dbObj, ...) sqliteConnectionInfo(dbObj, ...),
  valueClass = "list"
)
#' @export
sqliteConnectionInfo <- function(obj, what="", ...) {
  if(!isIdCurrent(obj))
    stop(paste("expired", class(obj)))
  id <- obj@Id
  info <- .Call("RSQLite_connectionInfo", id, PACKAGE = .SQLitePkgName)
  if(length(info$rsId)){
    rsId <- vector("list", length = length(info$rsId))
    for(i in seq(along.with = info$rsId))
      rsId[[i]] <- new("SQLiteResult",
        Id = .Call("DBI_newResultHandle",
          id, info$rsId[i], PACKAGE = .SQLitePkgName))
    info$rsId <- rsId
  }
  if(!missing(what))
    info[what]
  else
    info
}


#' @export
setMethod("dbGetException", "SQLiteConnection",
  definition = function(conn, ...){
    .Call("RS_SQLite_getException", conn@Id, PACKAGE = .SQLitePkgName)
  },
  valueClass = "list"    ## TODO: should return a SQLiteException
)
#' @export
setMethod("dbSendQuery",
  signature = signature(conn = "SQLiteConnection", statement = "character"),
  definition = function(conn, statement, ...){
    sqliteExecStatement(conn, statement, ...)
  },
  valueClass = "SQLiteResult"
)
#' @export
setMethod("dbSendPreparedQuery", 
  signature = signature(conn = "SQLiteConnection", statement = "character",
    bind.data = "data.frame"),
  definition = function(conn, statement, bind.data, ...){
    sqliteExecStatement(conn, statement, bind.data, ...)
  },
  valueClass = "SQLiteResult"
)
## submits the sql statement to SQLite and creates a
## dbResult object if the SQL operation does not produce
## output, otherwise it produces a resultSet that can
## be used for fetching rows.
#' @export
sqliteExecStatement <- function(con, statement, bind.data=NULL) {
  conId <- con@Id
  statement <- as(statement, "character")
  if (!is.null(bind.data)) {
    if (class(bind.data)[1] != "data.frame")
      bind.data <- as.data.frame(bind.data)
    if (min(dim(bind.data)) <= 0) {
      stop("bind.data must have non-zero dimensions")
    }
  }
  rsId <- .Call("RS_SQLite_exec",
    conId, statement, bind.data,
    PACKAGE = .SQLitePkgName)
  #  out <- new("SQLitedbResult", Id = rsId)
  #  if(dbGetInfo(out, what="isSelect")
  #    out <- new("SQLiteResultSet", Id = rsId)
  #  out
  out <- new("SQLiteResult", Id = rsId)
  out
}


#' @export
setMethod("dbGetQuery",
  signature = signature(conn = "SQLiteConnection", statement = "character"),
  definition = function(conn, statement, ...){
    sqliteQuickSQL(conn, statement, ...)
  },
)
#' @export
setMethod("dbGetPreparedQuery", 
  signature = signature(conn = "SQLiteConnection", statement = "character",
    bind.data = "data.frame"),
  definition = function(conn, statement, bind.data, ...){
    sqliteQuickSQL(conn, statement, bind.data, ...)
  },
  valueClass = "SQLiteResult"
)

## helper function: it exec's *and* retrieves a statement. It should
## be named something else.
#' @export
sqliteQuickSQL <- function(con, statement, bind.data=NULL, ...) {
  rs <- sqliteExecStatement(con, statement, bind.data)
  if(dbHasCompleted(rs)){
    dbClearResult(rs)            ## no records to fetch, we're done
    invisible()
    return(NULL)
  }
  res <- sqliteFetch(rs, n = -1, ...)
  if(dbHasCompleted(rs))
    dbClearResult(rs)
  else
    warning("pending rows")
  res
}


#' @export
setMethod("summary", "SQLiteConnection",
  definition = function(object, ...) sqliteDescribeConnection(object, ...)
)
#' @export
sqliteDescribeConnection <- function(obj, verbose = FALSE, ...) {
  if(!isIdCurrent(obj)){
    show(obj)
    invisible(return(NULL))
  }
  info <- dbGetInfo(obj)
  show(obj)
  cat("  Database name:", info$dbname, "\n")
  cat("  Loadable extensions:", info$loadableExtensions, "\n")
  cat("  File open flags:", info$falgs, "\n")
  cat("  Virtual File System:", info$vfs, "\n")
  cat("  SQLite engine version: ", info$serverVersion, "\n")
  cat("  Results Sets:\n")
  if(length(info$rsId)>0){
    for(i in seq(along.with = info$rsId)){
      cat("   ", i, " ")
      show(info$rsId[[i]])
    }
  } else
    cat("   No open result sets\n")
  invisible(NULL)
}

#' Call an SQL stored procedure
#' 
#' Not yet implemented.
#' 
#' @aliases dbCallProc,SQLiteConnection-method
#' @docType methods
#' @export
setMethod("dbCallProc", "SQLiteConnection",
  definition = function(conn, ...) .NotYetImplemented()
)

# Transactions -----------------

#' DBMS Transaction Management
#' 
#' By default, SQLite is in auto-commit mode. \code{dbBeginTransaction} starts
#' a SQLite transaction and turns auto-commit off. \code{dbCommit} and
#' \code{dbRollback} commit and rollback the transaction, respectively and turn
#' auto-commit on.
#' 
#' @aliases dbBeginTransaction dbBeginTransaction-methods
#' dbRollback-methods dbBeginTransaction,SQLiteConnection-method
#' dbCommit,SQLiteConnection-method dbRollback,SQLiteConnection-method
#' @docType methods
#' @section Methods: \describe{ \item{conn}{ a \code{SQLiteConnection} object,
#' as produced by the function \code{dbConnect}.  } \item{list()}{ any
#' database-specific arguments.  }\item{ }{ any database-specific arguments.  }
#' }
#' @examples
#' 
#' drv <- dbDriver("SQLite")
#' tfile <- tempfile()
#' con <- dbConnect(drv, dbname = tfile)
#' data(USArrests)
#' dbWriteTable(con, "arrests", USArrests)
#' dbGetQuery(con, "select count(*) from arrests")[1, ]
#' 
#' dbBeginTransaction(con)
#' rs <- dbSendQuery(con, "DELETE from arrests WHERE Murder > 1")
#' do_commit <- if (dbGetInfo(rs)[["rowsAffected"]] > 40) FALSE else TRUE
#' dbClearResult(rs)
#' dbGetQuery(con, "select count(*) from arrests")[1, ]
#' if (!do_commit)
#'     dbRollback(con)
#' dbGetQuery(con, "select count(*) from arrests")[1, ]
#' 
#' dbBeginTransaction(con)
#' rs <- dbSendQuery(con, "DELETE from arrests WHERE Murder > 5")
#' dbClearResult(rs)
#' dbCommit(con)
#' dbGetQuery(con, "select count(*) from arrests")[1, ]
#' 
#' dbDisconnect(con)
#' @name transactions
NULL

#' @export
setMethod("dbCommit", "SQLiteConnection",
  definition = function(conn, ...) sqliteTransactionStatement(conn, "COMMIT")
)

#' @export
setMethod("dbRollback", "SQLiteConnection",
  definition = function(conn, ...) {
    rsList <- dbListResults(conn)
    if (length(rsList))
      dbClearResult(rsList[[1]])
    sqliteTransactionStatement(conn, "ROLLBACK")
  }
)

#' @export
setMethod("dbBeginTransaction", "SQLiteConnection",
  definition = function(conn, ...) sqliteTransactionStatement(conn, "BEGIN")
)

## checks for any open resultsets, and closes them if completed.
## the statement is then executed on the connection, and returns
## whether it executed without an error or not.
#' @export
sqliteTransactionStatement <- function(con, statement) {
  ## are there resultSets pending on con?
  if(length(dbListResults(con)) > 0){
    res <- dbListResults(con)[[1]]
    if(!dbHasCompleted(res)){
      stop("connection with pending rows, close resultSet before continuing")
    }
    dbClearResult(res)
  }
  
  rc <- try(dbGetQuery(con, statement), silent = TRUE)
  !inherits(rc, ErrorClass)
}

# Data frame read/write ---------------

#' Convenience functions for Importing/Exporting DBMS tables
#' 
#' These functions mimic their R/S-Plus counterpart \code{get}, \code{assign},
#' \code{exists}, \code{remove}, and \code{objects}, except that they generate
#' code that gets remotely executed in a database engine.
#' 
#' 
#' @name dbReadTable-methods
#' @aliases dbReadTable-methods dbWriteTable-methods dbExistsTable-methods
#' dbRemoveTable-methods dbReadTable,SQLiteConnection,character-method
#' dbWriteTable,SQLiteConnection,character,data.frame-method
#' dbWriteTable,SQLiteConnection,character,character-method
#' dbExistsTable,SQLiteConnection,character-method
#' dbRemoveTable,SQLiteConnection,character-method
#' @docType methods
#' @return A data.frame in the case of \code{dbReadTable}; otherwise a logical
#' indicating whether the operation was successful.
#' @note Note that the data.frame returned by \code{dbReadTable} only has
#' primitive data, e.g., it does not coerce character data to factors.
#' 
#' SQLite table names are \emph{not} case sensitive, e.g., table names
#' \code{ABC} and \code{abc} are considered equal.
#' @section Methods: \describe{ \item{conn}{ an \code{SQLiteConnection}
#' database connection object.  } \item{name}{ a character string specifying a
#' table name.  } \item{value}{ a data.frame (or coercible to data.frame)
#' object or a file name (character).  In the first case, the data.frame is
#' written to a temporary file and then imported to SQLite; when \code{value}
#' is a character, it is interpreted as a file name and its contents imported
#' to SQLite.  } \item{row.names}{ in the case of \code{dbReadTable}, this
#' argument can be a string or an index specifying the column in the DBMS table
#' to be used as \code{row.names} in the output data.frame (a \code{NULL},
#' \code{""}, or 0 specifies that no column should be used as \code{row.names}
#' in the output).
#' 
#' In the case of \code{dbWriteTable}, this argument should be a logical
#' specifying whether the \code{row.names} should be output to the output DBMS
#' table; if \code{TRUE}, an extra field whose name will be whatever the
#' R/S-Plus identifier \code{"row.names"} maps to the DBMS (see
#' \code{\link[DBI]{make.db.names}}).  } \item{overwrite}{ a logical specifying
#' whether to overwrite an existing table or not.  Its default is \code{FALSE}.
#' (See the BUGS section below).  } \item{append}{ a logical specifying whether
#' to append to an existing table in the DBMS.  Its default is \code{FALSE}.  }
#' \item{list()}{ optional arguments.
#' 
#' When \code{dbWriteTable} is used to import data from a file, you may
#' optionally specify \code{header=}, \code{row.names=}, \code{col.names=},
#' \code{sep=}, \code{eol=}, \code{field.types=}, and \code{skip=}.
#' 
#' \code{header} is a logical indicating whether the first data line (but see
#' \code{skip}) has a header or not.  If missing, it value is determined
#' following \code{\link{read.table}} convention, namely, it is set to TRUE if
#' and only if the first row has one fewer field that the number of columns.
#' 
#' \code{row.names} is a logical to specify whether the first column is a set
#' of row names.  If missing its defualt follows the \code{\link{read.table}}
#' convention.
#' 
#' \code{col.names} a character vector with column names (these names will be
#' filtered with \code{\link[DBI]{make.db.names}} to ensure valid SQL
#' identifiers. (See also \code{field.types} below.)
#' 
#' The field separator \code{sep=} defaults to \code{','}.
#' 
#' The end-of-line delimiter \code{eol} defaults to \code{'\n'}.
#' 
#' \code{skip} specifies number of lines to skip before reading the data and it
#' defaults to 0.
#' 
#' \code{field.types} is a list of named field SQL types where
#' \code{names(field.types)} provide the new table's column names (if missing,
#' field types are inferred using \code{\link[DBI]{dbDataType}}).  }\item{ }{
#' optional arguments.
#' 
#' When \code{dbWriteTable} is used to import data from a file, you may
#' optionally specify \code{header=}, \code{row.names=}, \code{col.names=},
#' \code{sep=}, \code{eol=}, \code{field.types=}, and \code{skip=}.
#' 
#' \code{header} is a logical indicating whether the first data line (but see
#' \code{skip}) has a header or not.  If missing, it value is determined
#' following \code{\link{read.table}} convention, namely, it is set to TRUE if
#' and only if the first row has one fewer field that the number of columns.
#' 
#' \code{row.names} is a logical to specify whether the first column is a set
#' of row names.  If missing its defualt follows the \code{\link{read.table}}
#' convention.
#' 
#' \code{col.names} a character vector with column names (these names will be
#' filtered with \code{\link[DBI]{make.db.names}} to ensure valid SQL
#' identifiers. (See also \code{field.types} below.)
#' 
#' The field separator \code{sep=} defaults to \code{','}.
#' 
#' The end-of-line delimiter \code{eol} defaults to \code{'\n'}.
#' 
#' \code{skip} specifies number of lines to skip before reading the data and it
#' defaults to 0.
#' 
#' \code{field.types} is a list of named field SQL types where
#' \code{names(field.types)} provide the new table's column names (if missing,
#' field types are inferred using \code{\link[DBI]{dbDataType}}).  } }
#' @examples
#' \dontrun{
#' conn <- dbConnect("SQLite", dbname = "sqlite.db")
#' if(dbExistsTable(con, "fuel_frame")){
#'    dbRemoveTable(conn, "fuel_frame")
#'    dbWriteTable(conn, "fuel_frame", fuel.frame)
#' }
#' if(dbExistsTable(conn, "RESULTS")){
#'    dbWriteTable(conn, "RESULTS", results2000, append = TRUE)
#' else
#'    dbWriteTable(conn, "RESULTS", results2000)
#' }
#' }
#' 
NULL

#' @export
setMethod("dbExistsTable",
  signature = signature(conn = "SQLiteConnection", name = "character"),
  definition = function(conn, name, ...){
    lst <- dbListTables(conn)
    match(tolower(name), tolower(lst), nomatch = 0) > 0
  },
  valueClass = "logical"
)
#' @export
setMethod("dbReadTable",
  signature = signature(conn = "SQLiteConnection", name = "character"),
  definition = function(conn, name, ...) sqliteReadTable(conn, name, ...),
  valueClass = "data.frame"
)
## this is exactly the same as ROracle's oraReadTable
## Should we also allow row.names to be a character vector (as in read.table)?
## is it "correct" to set the row.names of output data.frame?
## Use NULL, "", or 0 as row.names to prevent using any field as row.names.
#' @export
sqliteReadTable <- function(con, name, row.names = "row_names",
  check.names = TRUE, ...) {
  out <- try(dbGetQuery(con, paste("SELECT * from", name)))
  if(inherits(out, ErrorClass))
    stop(paste("could not find table", name))
  if(check.names)
    names(out) <- make.names(names(out), unique = TRUE)
  ## should we set the row.names of the output data.frame?
  nms <- names(out)
  j <- switch(mode(row.names),
    character = if(row.names=="") 0 else
      match(tolower(row.names), tolower(nms),
        nomatch = if(missing(row.names)) 0 else -1),
    numeric=, logical = row.names,
    NULL = 0,
    0)
  if(as.numeric(j)==0)
    return(out)
  if(is.logical(j)) ## Must be TRUE
    j <- match(row.names, tolower(nms), nomatch=0)
  if(j<1 || j>ncol(out)){
    warning("row.names not set on output data.frame (non-existing field)")
    return(out)
  }
  rnms <- as.character(out[,j])
  if(all(!duplicated(rnms))){
    out <- out[,-j, drop = F]
    row.names(out) <- rnms
  } else warning("row.names not set on output (duplicate elements in field)")
  out
}

#' @export
setMethod("dbWriteTable",
  signature = signature(conn = "SQLiteConnection", name = "character",
    value="data.frame"),
  definition = function(conn, name, value, ...)
    sqliteWriteTable(conn, name, value, ...),
  valueClass = "logical"
)
#' @export
sqliteWriteTable <- function(con, name, value, row.names=TRUE,
  overwrite=FALSE, append=FALSE,
  field.types=NULL, ...) {
  if (overwrite && append)
    stop("overwrite and append cannot both be TRUE")
  
  ## Do we need to clone the connection (ie., if it is in use)?
  if (length(dbListResults(con))){
    new.con <- dbConnect(con)              # there's pending work, so clone
    on.exit(dbDisconnect(new.con))
  } else {
    new.con <- con
  }
  
  foundTable <- dbExistsTable(con, name)
  new.table <- !foundTable
  createTable <- (new.table || foundTable && overwrite)
  removeTable <- (foundTable && overwrite)
  success <- dbBeginTransaction(con)
  if (!success) {
    warning("unable to begin transaction")
    return(FALSE)
  }
  ## sanity check
  if (foundTable && !removeTable && !append) {
    warning(paste("table", name,
      "exists in database: aborting dbWriteTable"))
    success <- FALSE
  }
  
  if (removeTable) {
    success <- tryCatch({
      if (dbRemoveTable(con, name)) {
        TRUE
      } else {
        warning(paste("table", name, "couldn't be overwritten"))
        FALSE
      }
    }, error=function(e) {
      warning(conditionMessage(e))
      FALSE
    })
  }
  
  if (!success) {
    dbRollback(con)
    return(FALSE)
  }
  
  if (row.names) {
    ## Need to handle row.names at this level
    ## for the bind.data to work correctly.
    ##
    ## FIXME: for R >= 2.5, we should check
    ## for numeric row.names and not convert
    ## to character.
    value <- cbind(row.names(value), value, stringsAsFactors=FALSE)
    names(value)[1] <- "row.names"
  }
  
  if (createTable) {
    sql <- dbBuildTableDefinition(new.con, name, value,
      field.types=field.types,
      row.names=FALSE)
    success <- tryCatch({
      dbGetQuery(new.con, sql)
      TRUE
    }, error=function(e) {
      warning(conditionMessage(e))
      FALSE
    })
    if (!success) {
      dbRollback(con)
      return(FALSE)
    }
  }
  
  valStr <- paste(rep("?", ncol(value)), collapse=",")
  sql <- sprintf("insert into %s values (%s)",
    name, valStr)
  success <- tryCatch({
    ## The 'finally' expression will have access to
    ## this frame, not that of 'error'.  We want ret
    ## to be defined even if an error occurs.
    ret <- FALSE
    rs <- dbSendPreparedQuery(new.con, sql, bind.data=value)
    ret <- TRUE
  }, error=function(e) {
    warning(conditionMessage(e))
    ret <- FALSE
  }, finally={
    if (exists("rs"))
      dbClearResult(rs)
    ret
  })
  if (!success)
    dbRollback(con)
  else {
    success <- dbCommit(con)
    if (!success) {
      warning(dbGetException(con)[["errorMsg"]])
      dbRollback(con)
    }
  }
  success
}



#' Build the SQL CREATE TABLE definition as a string
#' 
#' Build the SQL CREATE TABLE definition as a string for the input data.frame
#' 
#' The output SQL statement is a simple \code{CREATE TABLE} with suitable for
#' \code{dbGetQuery}
#' 
#' @param dbObj any DBI object (used only to dispatch according to the engine
#' (e.g., MySQL, SQLite, Oracle)
#' @param name name of the new SQL table
#' @param value data.frame for which we want to create a table
#' @param field.types optional named list of the types for each field in
#' \code{value}
#' @param row.names logical, should row.name of \code{value} be exported as a
#' \code{row\_names} field? Default is \code{TRUE}
#' @param \dots reserved for future use
#' @return An SQL string
#' @export dbBuildTableDefinition
dbBuildTableDefinition <- function(dbObj, name, value, field.types = NULL, 
  row.names = TRUE, ...) {
  if(!is.data.frame(value))
    value <- as.data.frame(value)
  if(!is.null(row.names) && row.names){
    value  <- cbind(row.names(value), value)  ## can't use row.names= here
    names(value)[1] <- "row.names"
  }
  if(is.null(field.types)){
    ## the following mapping should be coming from some kind of table
    ## also, need to use converter functions (for dates, etc.)
    field.types <- sapply(value, dbDataType, dbObj = dbObj)
  }
  i <- match("row.names", names(field.types), nomatch=0)
  if(i>0) ## did we add a row.names value?  If so, it's a text field.
    field.types[i] <- dbDataType(dbObj, field.types[["row.names"]])
  names(field.types) <-
    make.db.names(dbObj, names(field.types), allow.keywords = FALSE)
  
  ## need to create a new (empty) table
  flds <- paste(names(field.types), field.types)
  paste("CREATE TABLE", name, "\n(", paste(flds, collapse=",\n\t"), "\n)")
}


## create/load table from a file via dbWriteTable (the argument
## value specifies a file name).  TODO, value a connection.
#' @export
setMethod("dbWriteTable",
  signature = signature(conn = "SQLiteConnection", name = "character",
    value="character"),
  definition = function(conn, name, value, ...)
    sqliteImportFile(conn, name, value, ...),
  valueClass = "logical"
)

#' @export
sqliteImportFile <- function(con, name, value, field.types = NULL, 
  overwrite = FALSE, append = FALSE, header, 
  row.names, nrows = 50, sep = ",", eol="\n", 
  skip = 0, ...) {
  if(overwrite && append)
    stop("overwrite and append cannot both be TRUE")
  
  ## Do we need to clone the connection (ie., if it is in use)?
  if(length(dbListResults(con))!=0){
    new.con <- dbConnect(con)              ## there's pending work, so clone
    on.exit(dbDisconnect(new.con))
  }
  else
    new.con <- con
  
  if(dbExistsTable(con,name)){
    if(overwrite){
      if(!dbRemoveTable(con, name)){
        warning(paste("table", name, "couldn't be overwritten"))
        return(FALSE)
      }
    }
    else if(!append){
      warning(paste("table", name, "exists in database: aborting dbWriteTable"))
      return(FALSE)
    }
  }
  
  ## compute full path name (have R expand ~, etc)
  fn <- file.path(dirname(value), basename(value))
  if(missing(header) || missing(row.names)){
    f <- file(fn, open="r")
    if(skip>0)
      readLines(f, n=skip)
    txtcon <- textConnection(readLines(f, n=2))
    flds <- count.fields.wrapper(file = txtcon, sep = sep, ...)
    close(txtcon)
    close(f)
    nf <- length(unique(flds))
  }
  if(missing(header)){
    header <- nf==2
  }
  if(missing(row.names)){
    if(header)
      row.names <- if(nf==2) TRUE else FALSE
    else
      row.names <- FALSE
  }
  
  new.table <- !dbExistsTable(con, name)
  if(new.table){
    ## need to init table, say, with the first nrows lines
    d <- read.table(fn, sep=sep, header=header, skip=skip, nrows=nrows,
      na.strings=.SQLite.NA.string,
      stringsAsFactors=FALSE, ...)
    sql <-
      dbBuildTableDefinition(new.con, name, d, field.types = field.types,
        row.names = row.names)
    rs <- try(dbSendQuery(new.con, sql))
    if(inherits(rs, ErrorClass)){
      warning("could not create table: aborting sqliteImportFile")
      return(FALSE)
    }
    else
      dbClearResult(rs)
  }
  else if(!append){
    warning(sprintf("table %s already exists -- use append=TRUE?", name))
  }
  rc <-
    try({
      skip <- skip + as.integer(header)
      conId <- con@Id
      .Call("RS_SQLite_importFile", conId, name, fn, sep, eol,
        as.integer(skip), PACKAGE = .SQLitePkgName)
    })
  if(inherits(rc, ErrorClass)){
    if(new.table) dbRemoveTable(new.con, name)
    return(FALSE)
  }
  TRUE
}

## wrapper for count.fields that accepts and ignores additional
## arguments passed via '...'. Note that this duplicates the default
## values of count.fields and will need to be updated if that function's
## defaults change.
#' @export
count.fields.wrapper <- function(file, sep = "", quote = "\"'", skip = 0,
  blank.lines.skip = TRUE,
  comment.char = "#", ...) {
  
  count.fields(file, sep, quote, skip, blank.lines.skip, comment.char)
}

#' @export
setMethod("dbRemoveTable",
  signature = signature(conn = "SQLiteConnection", name = "character"),
  definition = function(conn, name, ...){
    rc <- try(dbGetQuery(conn, paste("drop table", name)))
    !inherits(rc, ErrorClass)
  },
  valueClass = "logical"
)
#' @export
setMethod("dbListResults", "SQLiteConnection",
  definition = function(conn, ...) {
    rs <- dbGetInfo(conn, "rsId")[[1]]
    if(length(rs)>0) rs else list()
  },
  valueClass = "list"
)

#' List items from an SQLite DBMS and from objects
#' 
#' These methods are straight-forward implementations of the corresponding
#' generic functions.
#' 
#' 
#' @name dbListTables-methods
#' @aliases dbListTables-methods dbListFields-methods dbListConnections-methods
#' dbListResults-methods dbListTables,SQLiteConnection-method
#' dbListFields,SQLiteConnection,character-method
#' dbListConnections,SQLiteDriver-method dbListResults,SQLiteConnection-method
#' @docType methods
#' @section Methods: \describe{ \item{drv}{an \code{SQLiteDriver}.}
#' \item{conn}{an \code{SQLiteConnection}.} \item{name}{a character string with
#' the table name.} \item{list()}{currently not used.} }
#' @examples
#' \dontrun{
#' drv <- dbDriver("SQLite")
#' # after working awhile...
#' for(con in dbListConnections(odbc)){
#'    dbGetStatement(dbListResults(con))
#' }
#' }
#' 
NULL

#' @export
setMethod("dbListTables", "SQLiteConnection",
  definition = function(conn, ...){
    out <- dbGetQuery(conn, "SELECT name FROM
        (SELECT * FROM sqlite_master UNION ALL
         SELECT * FROM sqlite_temp_master)
        WHERE type = 'table' OR type = 'view'
        ORDER BY name", ...)
    if (is.null(out) || nrow(out) == 0)
      out <- character(0)
    else
      out <- out[, 1]
    out
  },
  valueClass = "character"
)
#' @export
setMethod("dbListFields",
  signature = signature(conn = "SQLiteConnection", name = "character"),
  definition = function(conn, name, ...) sqliteTableFields(conn, name, ...),
  valueClass = "character"
)
#' @export
sqliteTableFields <- function(con, name, ...) {
  if(length(dbListResults(con))>0){
    con2 <- dbConnect(con)
    on.exit(dbDisconnect(con2))
  }
  else
    con2 <- con
  rs <- dbSendQuery(con2, paste("select * from ", name, "limit 1"))
  dummy <- fetch(rs, n = 1)
  dbClearResult(rs)
  nms <- names(dummy)
  if(is.null(nms))
    character()
  else
    nms
}
