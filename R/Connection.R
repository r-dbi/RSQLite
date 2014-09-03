#' @include Object.R
#' @include ConnectionExtensions.R
NULL

#' Class SQLiteConnection.
#' 
#' \code{SQLiteConnection} objects are usually created by 
#' \code{\link[DBI]{dbConnect}}
#' 
#' @docType class
#' @examples
#' con <- dbConnect(SQLite(), dbname = tempfile())
#' dbDisconnect(con)
#' @export
setClass("SQLiteConnection", representation("DBIConnection", "SQLiteObject"))

#' Disconnect an SQLite connection.
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @export
#' @useDynLib RSQLite RS_SQLite_closeConnection
setMethod("dbDisconnect", "SQLiteConnection", function(conn) {
  if(!isIdCurrent(conn)){
    warning("expired SQLiteConnection")
    return(TRUE)
  }
  .Call(RS_SQLite_closeConnection, conn@Id)
})


#' Execute a SQL statement on a database connection
#' 
#' These are the primary methods for interacting with a database via SQL
#' queries.
#' 
#' @param conn an \code{\linkS4class{SQLiteConnection}} object.
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
#' dbDisconnect(con)
#' @export
setMethod("dbSendQuery",
  signature = signature(conn = "SQLiteConnection", statement = "character"),
  definition = function(conn, statement, ...){
    sqliteExecStatement(conn, statement, ...)
  },
  valueClass = "SQLiteResult"
)

#' @rdname dbSendQuery-SQLiteConnection-character-method
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

#' @rdname dbSendQuery-SQLiteConnection-character-method
#' @export
setMethod("dbGetQuery",
  signature = signature(conn = "SQLiteConnection", statement = "character"),
  definition = function(conn, statement, ...){
    sqliteQuickSQL(conn, statement, ...)
  },
)
#' @rdname dbSendQuery-SQLiteConnection-character-method
#' @export
setMethod("dbGetPreparedQuery", 
  signature = signature(conn = "SQLiteConnection", statement = "character",
    bind.data = "data.frame"),
  definition = function(conn, statement, bind.data, ...){
    sqliteQuickSQL(conn, statement, bind.data, ...)
  },
  valueClass = "SQLiteResult"
)

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

#' Get the last exception from the connection.
#' 
#' @param conn an object of class \code{\linkS4class{SQLiteConnection}}
#' @param ... Ignored. Needed for compatiblity with generic.
#' @export
#' @useDynLib RSQLite RS_SQLite_getException
setMethod("dbGetException", "SQLiteConnection",
  definition = function(conn){
    .Call(RS_SQLite_getException, conn@Id)
  }
)

#' Does the table exist?
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @param name character vector of length 1 giving name of table
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
#' @param name character vector of length 1 giving name of table to remove
#' @param ... Ignored. Included for compatibility with generic.
#' @export
setMethod("dbRemoveTable",
  signature = signature(conn = "SQLiteConnection", name = "character"),
  definition = function(conn, name, ...){
    rc <- try(dbGetQuery(conn, paste("DROP TABLE", name)))
    !inherits(rc, "try-error")
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
