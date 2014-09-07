#' @include ConnectionExtensions.R
NULL

#' Class SQLiteConnection.
#' 
#' \code{SQLiteConnection} objects are usually created by 
#' \code{\link[DBI]{dbConnect}}
#' 
#' @examples
#' con <- dbConnect(SQLite(), dbname = tempfile())
#' dbDisconnect(con)
#' @export
setClass("SQLiteConnection", 
  contains = "DBIConnection",
  slots = list(
    Id = "externalptr",
    dbname = "character", 
    loadable.extensions = "logical", 
    flags = "integer", 
    vfs = "character"
  )
)

#' Get the last exception from the connection.
#' 
#' @param conn an object of class \code{\linkS4class{SQLiteConnection}}
#' @export
#' @useDynLib RSQLite rsqlite_exception_info
#' @keywords internal
setMethod("dbGetException", "SQLiteConnection", function(conn) {
  .Call(rsqlite_exception_info, conn@Id)
})

#' Does the table exist?
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @param name String, name of table. Match is case insensitive.
#' @export
setMethod("dbExistsTable", c("SQLiteConnection", "character"),
  function(conn, name) {
    tolower(name) %in% tolower(dbListTables(conn))
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
  paste("CREATE TABLE", name, "\n(", paste(flds, collapse = ",\n\t"), "\n)")
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
