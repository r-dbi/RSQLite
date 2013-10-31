#' @include Object.R
NULL

#' Class SQLiteConnection
#' 
#' \code{SQLiteConnection} objects are usually created by 
#' \code{\link[DBI]{dbConnect}}
#' 
#' @docType class
#' @examples
#' con <- dbConnect(SQLite(), dbname = tempfile())
#' dbDisconnect(con)
#' dbUnloadDriver(drv)
#' @export
setClass("SQLiteConnection", representation("DBIConnection", "SQLiteObject"))

setAs("SQLiteConnection", "SQLiteDriver",
  def = function(from) new("SQLiteDriver", Id = from@Id)
)

#' Disconnect an SQLite connection.
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @param ... Ignored. Included for compatibility with generic.
#' @export
setMethod("dbDisconnect", "SQLiteConnection",
  definition = function(conn, ...) sqliteCloseConnection(conn, ...),
  valueClass = "logical"
)

#' @export
#' @rdname dbDisconnect-SQLiteConnection-method
sqliteCloseConnection <- function(con, ...) {
  if(!isIdCurrent(con)){
    warning(paste("expired SQLiteConnection"))
    return(TRUE)
  }
  .Call("RS_SQLite_closeConnection", con@Id, PACKAGE = .SQLitePkgName)
}


#' Execute a SQL statement on a database connection
#' 
#' These are the primary methods for interacting with a database via SQL
#' queries.
#' 
#' @param an \code{\linkS4class{SQLiteConnection}} object.
#' @param statement a character vector of length one specifying the SQL
#'   statement that should be executed.  Only a single SQL statment should be
#'   provided.
#' @param ... Ignored. Included for compatbility with generic.
#' @examples
#' con <- dbConnect(SQLite(), ":memory:")
#' data(USArrests)
#' dbWriteTable(con, "arrests", USArrests)
#' 
#' res <- dbSendQuery(con, "SELECT * from arrests")
#' data <- fetch(res, n = 2)
#' data
#' dbClearResult(res)
#' 
#' dbGetQuery(con, "SELECT * from arrests limit 3")
#' 
#' tryCatch(dbGetQuery(con, "SELECT * FROM tableDoesNotExist"),
#'          error=function(e) { print("caught") })
#' dbGetException(con)
#' 
#' ## The following example demonstrates the use of
#' ## transactions and bound parameters in prepared
#' ## statements.
#' 
#' set.seed(0x4554)
#' 
#' make_data <- function(n)
#' {
#'     alpha <- c(letters, as.character(0:9))
#'     make_key <- function(n)
#'     {
#'         paste(sample(alpha, n, replace = TRUE), collapse = "")
#'     }
#'     keys <- sapply(sample(1:5, replace=TRUE), function(x) make_key(x))
#'     counts <- sample(seq_len(1e4), n, replace = TRUE)
#'     data.frame(key = keys, count = counts, stringsAsFactors = FALSE)
#' }
#' 
#' key_counts <- make_data(100)
#' 
#' 
#' db <- dbConnect(SQLite(), dbname = ":memory:")
#' 
#' sql <- "
#' create table keys (key text, count integer)
#' "
#' 
#' dbGetQuery(db, sql)
#' 
#' bulk_insert <- function(sql, key_counts)
#' {
#'     dbBeginTransaction(db)
#'     dbGetPreparedQuery(db, sql, bind.data = key_counts)
#'     dbCommit(db)
#'     dbGetQuery(db, "select count(*) from keys")[[1]]
#' }
#' 
#' ##  for all styles, you can have up to 999 parameters
#' 
#' ## anonymous
#' sql <- "insert into keys values (?, ?)"
#' bulk_insert(sql, key_counts)
#' 
#' 
#' ## named w/ :, $, @@
#' ## names are matched against column names of bind.data
#' 
#' sql <- "insert into keys values (:key, :count)"
#' bulk_insert(sql, key_counts[ , 2:1])
#' 
#' sql <- "insert into keys values ($key, $count)"
#' bulk_insert(sql, key_counts)
#' 
#' sql <- "insert into keys values (@@key, @@count)"
#' bulk_insert(sql, key_counts)
#' 
#' ## indexed (NOT CURRENTLY SUPPORTED)
#' ## sql <- "insert into keys values (?1, ?2)"
#' ## bulk_insert(sql)
#' 
#' sql <- "select * from keys where count = :cc"
#' dbGetPreparedQuery(db, sql, data.frame(cc = c(95, 403)))
#' 
#' dbDisconnect(db)
#' 
#' @export
setMethod("dbSendQuery",
  signature = signature(conn = "SQLiteConnection", statement = "character"),
  definition = function(conn, statement, ...){
    sqliteExecStatement(conn, statement, ...)
  },
  valueClass = "SQLiteResult"
)

#' @rdname dbSendQuery-SQLiteConnection--character-method
#' @param bind.data A data frame of data to be bound.
#' @export
setMethod("dbSendPreparedQuery", 
  signature = signature(conn = "SQLiteConnection", statement = "character",
    bind.data = "data.frame"),
  definition = function(conn, statement, bind.data, ...){
    sqliteExecStatement(conn, statement, bind.data, ...)
  },
  valueClass = "SQLiteResult"
)

#' @rdname dbSendQuery-SQLiteConnection--character-method
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

#' @rdname dbSendQuery-SQLiteConnection--character-method
#' @export
setMethod("dbGetQuery",
  signature = signature(conn = "SQLiteConnection", statement = "character"),
  definition = function(conn, statement, ...){
    sqliteQuickSQL(conn, statement, ...)
  },
)
#' @rdname dbSendQuery-SQLiteConnection--character-method
#' @export
setMethod("dbGetPreparedQuery", 
  signature = signature(conn = "SQLiteConnection", statement = "character",
    bind.data = "data.frame"),
  definition = function(conn, statement, bind.data, ...){
    sqliteQuickSQL(conn, statement, bind.data, ...)
  },
  valueClass = "SQLiteResult"
)

#' @rdname dbSendQuery-SQLiteConnection--character-method
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

#' Call an SQL stored procedure
#' 
#' Not yet implemented.
#' 
#' @keywords internal
#' @export
setMethod("dbCallProc", "SQLiteConnection",
  definition = function(conn, ...) .NotYetImplemented()
)

# Transactions -----------------------------------------------------------------

#' SQLite transaction management.
#' 
#' By default, SQLite is in auto-commit mode. \code{dbBeginTransaction} starts
#' a SQLite transaction and turns auto-commit off. \code{dbCommit} and
#' \code{dbRollback} commit and rollback the transaction, respectively and turn
#' auto-commit on.
#' 
#' @param conn a \code{\linkS4class{SQLiteConnection}} object, produced by
#'   \code{\link[DBI](dbConnect)}
#' @param ... Ignored. Needed for compatibility with generic.
#' @examples
#' con <- dbConnect(SQLite(), dbname = tempfile())
#' data(USArrests)
#' dbWriteTable(con, "arrests", USArrests)
#' dbGetQuery(con, "select count(*) from arrests")[1, ]
#' 
#' dbBeginTransaction(con)
#' rs <- dbSendQuery(con, "DELETE from arrests WHERE Murder > 1")
#' do_commit <- if (dbGetInfo(rs)[["rowsAffected"]] > 40) FALSE else TRUE
#' dbClearResult(rs)
#' dbGetQuery(con, "select count(*) from arrests")[1, ]
#' if (!do_commit) dbRollback(con)
#' dbGetQuery(con, "select count(*) from arrests")[1, ]
#' 
#' dbBeginTransaction(con)
#' rs <- dbSendQuery(con, "DELETE FROM arrests WHERE Murder > 5")
#' dbClearResult(rs)
#' dbCommit(con)
#' dbGetQuery(con, "SELECT count(*) FROM arrests")[1, ]
#' 
#' dbDisconnect(con)
#' @name transactions
NULL

#' @export
#' @rdname transactions
setMethod("dbCommit", "SQLiteConnection",
  definition = function(conn, ...) sqliteTransactionStatement(conn, "COMMIT")
)

#' @export
#' @rdname transactions
setMethod("dbRollback", "SQLiteConnection",
  definition = function(conn, ...) {
    rsList <- dbListResults(conn)
    if (length(rsList))
      dbClearResult(rsList[[1]])
    sqliteTransactionStatement(conn, "ROLLBACK")
  }
)

#' @export
#' @rdname transactions
setMethod("dbBeginTransaction", "SQLiteConnection",
  definition = function(conn, ...) sqliteTransactionStatement(conn, "BEGIN")
)

#' @export
#' @rdname transactions
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

# Data frame read/write --------------------------------------------------------

#' Convenience functions for importing/exporting DBMS tables
#' 
#' These functions mimic their R/S-Plus counterpart \code{get}, \code{assign},
#' \code{exists}, \code{remove}, and \code{objects}, except that they generate
#' code that gets remotely executed in a database engine.
#' 
#' @return A data.frame in the case of \code{dbReadTable}; otherwise a logical
#' indicating whether the operation was successful.
#' @note Note that the data.frame returned by \code{dbReadTable} only has
#' primitive data, e.g., it does not coerce character data to factors.
#' 
#' @param conn a \code{\linkS4class{SQLiteConnection}} object, produced by
#'   \code{\link[DBI](dbConnect)}
#' @param name} a character string specifying a table name. SQLite table names 
#'   are \emph{not} case sensitive, e.g., table names \code{ABC} and \code{abc} 
#'   are considered equal.
#' @param value a data.frame (or coercible to data.frame) object or a 
#'   file name (character).  In the first case, the data.frame is
#'   written to a temporary file and then imported to SQLite; when \code{value}
#'   is a character, it is interpreted as a file name and its contents imported
#'   to SQLite.
#' @param row.names in the case of \code{dbReadTable}, this argument can be a 
#'   string or an index specifying the column in the DBMS table to be used as 
#'   \code{row.names} in the output data.frame (a \code{NULL}, \code{""}, or 0
#'   specifies that no column should be used as \code{row.names}
#'   in the output.
#' 
#'   In the case of \code{dbWriteTable}, this argument should be a logical
#'   specifying whether the \code{row.names} should be output to the output DBMS
#'   table; if \code{TRUE}, an extra field whose name will be whatever the
#'   R identifier \code{"row.names"} maps to the DBMS (see
#'   \code{\link[DBI]{make.db.names}}).  }
#' @param overwrite a logical specifying whether to overwrite an existing table 
#'   or not. Its default is \code{FALSE}. (See the BUGS section below)
#' @param append a logical specifying whether to append to an existing table 
#'   in the DBMS.  Its default is \code{FALSE}.
#' @param ... Ignored. Needed for compatibility with generic.
#' @param header is a logical indicating whether the first data line (but see
#' \code{skip}) has a header or not.  If missing, it value is determined
#' following \code{\link{read.table}} convention, namely, it is set to TRUE if
#' and only if the first row has one fewer field that the number of columns.
#' @param col.names a character vector with column names (these names will be
#'   filtered with \code{\link[DBI]{make.db.names}} to ensure valid SQL
#'   identifiers. (See also \code{field.types} below.)
#' @param sep The field separator, defaults to \code{','}.
#' @param eol The end-of-line delimiter, defaults to \code{'\n'}.
#' @param number of lines to skip before reading the data. Defaults to 0.
#' @param field.types character vector of named  SQL field types where
#'   the names are the names of new table's columns. If missing, types inferred
#'   with \code{\link[DBI]{dbDataType}}).
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
#' @name sqlite-io
NULL

#' @export
#' @rdname sqlite-io
setMethod("dbReadTable",
  signature = signature(conn = "SQLiteConnection", name = "character"),
  definition = function(conn, name, ...) sqliteReadTable(conn, name, ...),
  valueClass = "data.frame"
)

#' @export
#' @rdname sqlite-io
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
#' @rdname sqlite-io
sqliteWriteTable <- function(con, name, value, row.names = TRUE, 
                             overwrite = FALSE, append = FALSE, 
                             field.types = NULL, ...) {
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

#' @export
#' @rdname sqlite-io
setMethod("dbWriteTable",
  signature = signature(conn = "SQLiteConnection", name = "character",
    value="character"),
  definition = function(conn, name, value, ...)
    sqliteImportFile(conn, name, value, ...),
  valueClass = "logical"
)

#' @export
#' @rdname sqlite-io
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
#' @rdname sqlite-io
count.fields.wrapper <- function(file, sep = "", quote = "\"'", skip = 0,
  blank.lines.skip = TRUE,
  comment.char = "#", ...) {
  
  count.fields(file, sep, quote, skip, blank.lines.skip, comment.char)
}

#' Does the table exist?
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @param ... Ignored. Included for compatibility with generic.
#' @export
setMethod("dbExistsTable",
  signature = signature(conn = "SQLiteConnection", name = "character"),
  definition = function(conn, name, ...){
    lst <- dbListTables(conn)
    match(tolower(name), tolower(lst), nomatch = 0) > 0
  },
  valueClass = "logical"
)

#' Build the SQL CREATE TABLE definition as a string
#' 
#' The output SQL statement is a simple \code{CREATE TABLE} with suitable for
#' \code{dbGetQuery}
#' 
#' @param dbObj The object created by \code{\link{SQLite}}
#' @param name name of the new SQL table
#' @param value data.frame for which we want to create a table
#' @param field.types optional named list of the types for each field in
#'   \code{value}
#' @param row.names logical, should row.name of \code{value} be exported as a
#'   \code{row\_names} field? Default is \code{TRUE}
#' @param ... Ignored. Reserved for future use.
#' @return An SQL string
#' @export
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


#' Remove a table from the database.
#' 
#' Executes the SQL \code{DROP TABLE}.
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @param ... Ignored. Included for compatibility with generic.
#' @export
setMethod("dbRemoveTable",
  signature = signature(conn = "SQLiteConnection", name = "character"),
  definition = function(conn, name, ...){
    rc <- try(dbGetQuery(conn, paste("DROP TABLE", name)))
    !inherits(rc, ErrorClass)
  },
  valueClass = "logical"
)

#' List available SQLite result sets.
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @param ... Ignored. Included for compatibility with generic.
#' @export
setMethod("dbListResults", "SQLiteConnection",
  definition = function(conn, ...) {
    rs <- dbGetInfo(conn, "rsId")[[1]]
    if(length(rs)>0) rs else list()
  },
  valueClass = "list"
)

#' List available SQLite tables.
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @param ... Ignored. Included for compatibility with generic.
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

#' List fields in specified table.
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @param name a length 1 character vector giving the name of a table.
#' @param ... Ignored. Included for compatibility with generic.
#' @export
#' @export
setMethod("dbListFields",
  signature = signature(conn = "SQLiteConnection", name = "character"),
  definition = function(conn, name, ...) sqliteTableFields(conn, name, ...),
  valueClass = "character"
)
#' @export
#' @rdname dbListFields-SQLiteConnection--character-method
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
