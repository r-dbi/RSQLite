#' Write a local data frame or file to the database.
#' 
#' @export
#' @rdname dbWriteTable
#' @param conn a \code{\linkS4class{SQLiteConnection}} object, produced by
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
#'   or not. Its default is \code{FALSE}. (See the BUGS section below)
#' @param append a logical specifying whether to append to an existing table 
#'   in the DBMS.  Its default is \code{FALSE}.
#' @param field.types character vector of named  SQL field types where
#'   the names are the names of new table's columns. If missing, types inferred
#'   with \code{\link[DBI]{dbDataType}}).
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
    
    value <- explict_rownames(value, row.names)
    
    if (!found || overwrite) {
      sql <- sqliteBuildTableDefinition(conn, name, value, 
        field.types = field.types, row.names = FALSE)
      dbGetQuery(conn, sql)
    }
    
    if (nrow(value) > 0) {
      valStr <- paste(rep("?", ncol(value)), collapse = ",")
      sql <- sprintf("insert into %s values (%s)", name, valStr)
      rs <- dbSendPreparedQuery(conn, sql, bind.data = value)
      dbClearResult(rs)
    }

    on.exit(NULL)
    dbCommit(conn, "dbWriteTable")
    TRUE
  }
)

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
#' @useDynLib RSQLite RS_SQLite_importFile
#' @export
#' @rdname dbWriteTable
setMethod("dbWriteTable", c("SQLiteConnection", "character", "character"),
  function(conn, name, value, field.types = NULL, overwrite = FALSE, 
           append = FALSE, header = TRUE, colClasses = NA, row.names = FALSE, 
           nrows = 50, sep = ",", eol="\n", skip = 0) {
    if(overwrite && append)
      stop("overwrite and append cannot both be TRUE")
    value <- path.expand(value)
    
    dbBegin(conn)
    on.exit(dbRollback(conn))
    
    found <- dbExistsTable(conn, name)
    if (found && !overwrite && !append) {
      stop("Table ", name, " exists in database, and both overwrite and", 
        " append are FALSE", call. = FALSE)
    }
    if (found && overwrite) {
      dbRemoveTable(conn, name)
    }
    
    if (!found || overwrite) {
      # Initialise table with first `nrows` lines
      d <- read.table(value, sep = sep, header = header, skip = skip, nrows = nrows,
        na.strings = .SQLite.NA.string, comment.char = "", colClasses = colClasses,
        stringsAsFactors = FALSE)
      sql <- sqliteBuildTableDefinition(conn, name, d, field.types = field.types,
        row.names = row.names)
      dbGetQuery(conn, sql)
    }
    
    skip <- skip + as.integer(header)
    .Call(RS_SQLite_importFile, conn@Id, name, value, sep, eol, as.integer(skip))
    
    on.exit(NULL)
    dbCommit(conn)
    TRUE
  }
)
