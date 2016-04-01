#' @include SQLiteConnection.R
NULL

#' Write a local data frame or file to the database.
#' 
#' @export
#' @rdname dbWriteTable
#' @param con,conn a \code{\linkS4class{SQLiteConnection}} object, produced by
#'   \code{\link[DBI]{dbConnect}}
#' @param name a character string specifying a table name. SQLite table names 
#'   are \emph{not} case sensitive, e.g., table names \code{ABC} and \code{abc} 
#'   are considered equal.
#' @param value a data.frame (or coercible to data.frame) object or a 
#'   file name (character).  In the first case, the data.frame is
#'   written to a temporary file and then imported to SQLite; when \code{value}
#'   is a character, it is interpreted as a file name and its contents imported
#'   to SQLite.
#' @param row.names A logical specifying whether the \code{row.names} should be 
#'   output to the output DBMS table; if \code{TRUE}, an extra field whose name 
#'   will be whatever the R identifier \code{"row.names"} maps to the DBMS (see
#'   \code{\link[DBI]{make.db.names}}). If \code{NA} will add rows names if
#'   they are characters, otherwise will ignore.
#' @param overwrite a logical specifying whether to overwrite an existing table 
#'   or not. Its default is \code{FALSE}.
#' @param append a logical specifying whether to append to an existing table 
#'   in the DBMS.  Its default is \code{FALSE}.
#' @param field.types character vector of named  SQL field types where
#'   the names are the names of new table's columns. If missing, types inferred
#'   with \code{\link[DBI]{dbDataType}}).
#' @details In a primary key column qualified with 
#' \href{https://www.sqlite.org/autoinc.html}{\code{AUTOINCREMENT}}, missing
#' values will be assigned the next largest positive integer,
#' while nonmissing elements/cells retain their value.  If the 
#' autoincrement column exists in the \code{data.frame} 
#' (passed to \code{dbWriteTable}'s \code{value} parameter), the \code{NA} 
#' elements are overwritten. 
#' Similarly, if the key column is not present in the \code{data.frame}, all
#' elements are automatically assigned a value.
#' @export
#' @examples
#' con <- dbConnect(SQLite())
#' dbWriteTable(con, "mtcars", mtcars)
#' dbReadTable(con, "mtcars")
#' 
#' # A zero row data frame just creates a table definition.
#' dbWriteTable(con, "mtcars2", mtcars[0, ])
#' dbReadTable(con, "mtcars2")
#' 
#' dbDisconnect(con)
setMethod("dbWriteTable", c("SQLiteConnection", "character", "data.frame"),
  function(conn, name, value, row.names = NA, overwrite = FALSE, append = FALSE, 
    field.types = NULL) {
    
    if (overwrite && append)
      stop("overwrite and append cannot both be TRUE", call. = FALSE)
    
    dbBegin(conn, "dbWriteTable")
    on.exit(dbRollback(conn, "dbWriteTable"))
    
    found <- dbExistsTable(conn, name)
    if (found && !overwrite && !append) {
      stop("Table ", name, " exists in database, and both overwrite and", 
        " append are FALSE", call. = FALSE)
    }
    if (found && overwrite) {
      dbRemoveTable(conn, name)
    }
    
    if (!found || overwrite) {
      sql <- sqlCreateTable(conn, name, value, row.names = row.names)
      dbGetQuery(conn, sql)
    }
    
    if (nrow(value) > 0) {
      value <- sqlData(conn, value, row.names = row.names)
      sql <- parameterised_insert(conn, name, value)
      rs <- dbSendQuery(conn, sql)
      
      names(value) <- rep("", length(value))
      tryCatch(
        rsqlite_bind_rows(rs@ptr, value),
        finally = dbClearResult(rs)
      )
    }
    
    on.exit(NULL)
    dbCommit(conn, "dbWriteTable")
    TRUE
  }
)

parameterised_insert <- function(con, name, values) {
  table <- dbQuoteIdentifier(con, name)
  fields <- dbQuoteIdentifier(con, names(values))
  
  # Convert fields into a character matrix
  SQL(paste0(
    "INSERT INTO ", table, "\n",
    "  (", paste(fields, collapse = ", "), ")\n",
    "VALUES\n",
    paste0("  (", paste(rep("?", length(fields)), collapse = ", "), ")", collapse = ",\n")
  ))
  
}


#' @param header is a logical indicating whether the first data line (but see
#'   \code{skip}) has a header or not.  If missing, it value is determined
#'   following \code{\link{read.table}} convention, namely, it is set to TRUE if
#'   and only if the first row has one fewer field that the number of columns.
#' @param sep The field separator, defaults to \code{','}.
#' @param eol The end-of-line delimiter, defaults to \code{'\n'}.
#' @param skip number of lines to skip before reading the data. Defaults to 0.
#' @param nrows Number of rows to read to determine types.
#' @param colClasses Character vector of R type names, used to override
#'   defaults when imputing classes from on-disk file.
#' @export
#' @rdname dbWriteTable
setMethod("dbWriteTable", c("SQLiteConnection", "character", "character"),
  function(conn, name, value, field.types = NULL, overwrite = FALSE, 
    append = FALSE, header = TRUE, colClasses = NA, row.names = FALSE, 
    nrows = 50, sep = ",", eol="\n", skip = 0) {
    
    stop("Deprecated. This will come back at some point in the future")
  }
)

#' @export
#' @rdname dbWriteTable
setMethod("sqlData", "SQLiteConnection", function(con, value, row.names = NA) {
  value <- sqlRownamesToColumn(value, row.names)
  
  # Convert factors to strings
  is_factor <- vapply(value, is.factor, logical(1))
  value[is_factor] <- lapply(value[is_factor], as.character)
  
  # Convert all strings to utf-8
  is_char <- vapply(value, is.character, logical(1))
  value[is_char] <- lapply(value[is_char], enc2utf8)
  
  value
})

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
#'   \code{\link[DBI]{dbConnect}}
#' @param name a character string specifying a table name. SQLite table names 
#'   are \emph{not} case sensitive, e.g., table names \code{ABC} and \code{abc} 
#'   are considered equal.
#' @param check.names If \code{TRUE}, the default, column names will be
#'   converted to valid R identifiers.
#' @param select.cols  A SQL statement (in the form of a character vector of 
#'    length 1) giving the columns to select. E.g. "*" selects all columns, 
#'    "x,y,z" selects three columns named as listed.
#' @inheritParams DBI::sqlRownamesToColumn
#' @export
#' @examples
#' library(DBI)
#' con <- dbConnect(SQLite())
#' dbWriteTable(con, "mtcars", mtcars)
#' dbReadTable(con, "mtcars")
#' dbGetQuery(con, "SELECT * FROM mtcars WHERE cyl = 8")
#' 
#' # Supress row names
#' dbReadTable(con, "mtcars", row.names = FALSE)
#' dbGetQuery(con, "SELECT * FROM mtcars WHERE cyl = 8", row.names = FALSE)
#' 
#' dbDisconnect(con)
setMethod("dbReadTable", c("SQLiteConnection", "character"),
  function(conn, name, row.names = NA, check.names = TRUE, select.cols = "*") {
    name <- dbQuoteIdentifier(conn, name)
    out <- dbGetQuery(conn, paste("SELECT", select.cols, "FROM",
                                  dbQuoteIdentifier(conn, name)),
      row.names = row.names)
    
    if (check.names) {
      names(out) <- make.names(names(out), unique = TRUE)
    }
    
    out
  }
)


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


#' Remove a table from the database.
#' 
#' Executes the SQL \code{DROP TABLE}.
#' 
#' @param conn An existing \code{\linkS4class{SQLiteConnection}}
#' @param name character vector of length 1 giving name of table to remove
#' @export
setMethod("dbRemoveTable", c("SQLiteConnection", "character"),
  function(conn, name) {
    dbGetQuery(conn, paste("DROP TABLE ", dbQuoteIdentifier(conn, name)))
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
    rs <- dbSendQuery(conn, paste("SELECT * FROM ",
                                  dbQuoteIdentifier(conn, name), "LIMIT 1"))
    on.exit(dbClearResult(rs))
    
    names(fetch(rs, n = 1))
  }
)


#' Determine the SQL Data Type of an R object.
#' 
#' This method is a straight-forward implementation of the corresponding
#' generic function.
#' 
#' @param dbObj a \code{SQLiteDriver} object,
#' @param obj an R object whose SQL type we want to determine.
#' @param ... Needed for compatibility with generic. Otherwise ignored.
#' @examples
#' dbDataType(SQLite(), 1)
#' dbDataType(SQLite(), 1L)
#' dbDataType(SQLite(), "1")
#' dbDataType(SQLite(), TRUE)
#' dbDataType(SQLite(), list())
#' 
#' sapply(datasets::quakes, dbDataType, dbObj = SQLite())
#' @export
setMethod("dbDataType", "SQLiteConnection", function(dbObj, obj, ...) {
  dbDataType(SQLite(), obj, ...)
})

#' @rdname dbDataType-SQLiteConnection-ANY-method
#' @export
setMethod("dbDataType", "SQLiteDriver", function(dbObj, obj, ...) {
  if (is.factor(obj)) return("TEXT")
  
  switch(typeof(obj), 
    integer = "INTEGER",
    double = "REAL",
    character = "TEXT",
    logical = "INTEGER",
    list = "BLOB",
    stop("Unsupported type", call. = FALSE)
  )
})


