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
setClass("SQLiteConnection", 
  contains = "DBIConnection",
  slots = list(Id = "externalptr")
)


#' Execute a SQL statement on a database connection
#' 
#' These are the primary methods for interacting with a database via SQL
#' queries.
#' 
#' @param conn an \code{\linkS4class{SQLiteConnection}} object.
#' @param statement a character vector of length one specifying the SQL
#'   statement that should be executed.  Only a single SQL statment should be
#'   provided.
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
#' dbClearResult(res)
#' 
#' # Use dbSendPreparedQuery/dbGetPreparedQuery for "prepared" queries
#' dbGetPreparedQuery(con, "SELECT * FROM arrests WHERE Murder < ?", 
#'    data.frame(x = 3))
#' dbGetPreparedQuery(con, "SELECT * FROM arrests WHERE Murder < (:x)", 
#'    data.frame(x = 3))
#' 
#' dbDisconnect(con)
#' @export
setMethod("dbSendQuery", c("SQLiteConnection", "character"),
  function(conn, statement) {
    sqliteSendQuery(conn, statement)
  }
)

#' @rdname dbSendQuery-SQLiteConnection-character-method
#' @param bind.data A data frame of data to be bound.
#' @export
setMethod("dbSendPreparedQuery", 
  c("SQLiteConnection", "character", "data.frame"),
  function(conn, statement, bind.data) {
    sqliteSendQuery(conn, statement, bind.data)
  }
)

#' @useDynLib RSQLite RS_SQLite_exec
sqliteSendQuery <- function(con, statement, bind.data = NULL) {
  if (!is.null(bind.data)) {
    if (!is.data.frame(bind.data)) {
      bind.data <- as.data.frame(bind.data)
    }
    if (nrow(bind.data) == 0 || ncol(bind.data) == 0) {
      stop("bind.data must have non-zero dimensions")
    }
  }
  
  rsId <- .Call(RS_SQLite_exec, con@Id, as.character(statement), bind.data)
  new("SQLiteResult", Id = rsId)
}

#' @rdname dbSendQuery-SQLiteConnection-character-method
#' @export
setMethod("dbGetQuery", c("SQLiteConnection", "character"),
  function(conn, statement){
    sqliteGetQuery(conn, statement)
  },
)
#' @rdname dbSendQuery-SQLiteConnection-character-method
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

#' Get the last exception from the connection.
#' 
#' @param conn an object of class \code{\linkS4class{SQLiteConnection}}
#' @export
#' @useDynLib RSQLite RS_SQLite_getException
setMethod("dbGetException", "SQLiteConnection", function(conn) {
  .Call(RS_SQLite_getException, conn@Id)
})

#' Does the table exist?
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @param name character vector of length 1 giving name of table
#' @export
setMethod("dbExistsTable", c("SQLiteConnection", "character"),
  function(conn, name){
    lst <- dbListTables(conn)
    match(tolower(name), tolower(lst), nomatch = 0) > 0
  }
)

#' Build the SQL CREATE TABLE definition as a string
#' 
#' The output SQL statement is a simple \code{CREATE TABLE} with suitable for
#' \code{dbGetQuery}
#' 
#' @param conn A database connection.
#' @param name Name of the new SQL table
#' @param value A data.frame, for which we want to create a table.
#' @param field.types Optional, named character vector of the types for each 
#'   field in \code{value}
#' @param row.names Logical. Should row.name of \code{value} be exported as a
#'   \code{row\_names} field? Default is \code{TRUE}
#' @return An SQL string
#' @keywords internal
#' @aliases dbBuildTableDefinition
#' @export
sqliteBuildTableDefinition <- function(con, name, value, field.types = NULL, 
                                       row.names = NA) {
  if (!is.data.frame(value)) {
    value <- as.data.frame(value)
  }
  value <- explict_rownames(value, row.names)

  if (is.null(field.types)) {
    field.types <- vapply(value, dbDataType, dbObj = con, 
      FUN.VALUE = character(1))
  }
  # Escape field names
  names(field.types) <- dbQuoteIdentifier(con, names(field.types))
    
  flds <- paste(names(field.types), field.types)
  paste("CREATE TABLE", name, "\n(", paste(flds, collapse=",\n\t"), "\n)")
}

#' @export
dbBuildTableDefinition <- function(...) {
  .Deprecated("sqliteBuildTableDefinition")
  sqliteBuildTableDefinition(...)
}
  

#' Remove a table from the database.
#' 
#' Executes the SQL \code{DROP TABLE}.
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @param name character vector of length 1 giving name of table to remove
#' @export
setMethod("dbRemoveTable", c("SQLiteConnection", "character"),
  function(conn, name) {
    dbGetQuery(conn, paste("DROP TABLE ", name))
    invisible(TRUE)
  }
)

#' List available SQLite result sets.
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @export
setMethod("dbListResults", "SQLiteConnection", function(conn) {
  dbGetInfo(conn)$rsId
})

#' List available SQLite tables.
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @export
setMethod("dbListTables", "SQLiteConnection", function(conn) {
  dbGetQuery(conn, "SELECT name FROM
    (SELECT * FROM sqlite_master UNION ALL SELECT * FROM sqlite_temp_master)
    WHERE type = 'table' OR type = 'view'
    ORDER BY name")$name
})

#' List fields in specified table.
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @param name a length 1 character vector giving the name of a table.
#' @export
#' @examples
#' con <- dbConnect(SQLite())
#' dbWriteTable(con, "iris", iris)
#' dbListFields(con, "iris")
#' dbDisconnect(con)
setMethod("dbListFields", c("SQLiteConnection", "character"),
  function(conn, name) {
    rs <- dbSendQuery(conn, paste("SELECT * FROM ", name, "LIMIT 1"))
    on.exit(dbClearResult(rs))
    
    names(fetch(rs, n = 1))
  }
)
