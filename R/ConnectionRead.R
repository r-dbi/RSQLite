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
#' @param conn,con a \code{\linkS4class{SQLiteConnection}} object, produced by
#'   \code{\link[DBI]{dbConnect}}
#' @param name a character string specifying a table name. SQLite table names 
#'   are \emph{not} case sensitive, e.g., table names \code{ABC} and \code{abc} 
#'   are considered equal.
#' @param check.names If \code{TRUE}, the default, column names will be
#'   converted to valid R identifiers.
#' @param row.names A string or an index specifying the column in the DBMS table 
#'   to use as \code{row.names} in the output data.frame (a \code{NULL}, 
#'   \code{""}, or 0 specifies that no column should be used as \code{row.names}
#'   in the output.)
#' @param select.cols  A SQL statement (in the form of a character vector of 
#'    length 1) giving the columns to select. E.g. "*" selects all columns, 
#'    "x,y,z" selects three columns named as listed.
#' @export
#' @examples
#' con <- dbConnect(SQLite())
#' dbWriteTable(con, "mtcars", mtcars)
#' dbReadTable(con, "mtcars")
#' 
#' dbDisconnect(con)
setMethod("dbReadTable", c("SQLiteConnection", "character"),
  function(conn, name, row.names = "row_names", check.names = TRUE, 
           select.cols = "*") {
    out <- dbGetQuery(conn, paste("SELECT", select.cols, "FROM", name))
    
    if(check.names) {
      names(out) <- make.names(names(out), unique = TRUE)
    }
    
    ## should we set the row.names of the output data.frame?
    nms <- names(out)
    if (is.character(row.names)) {
      row.names <- match(tolower(row.names), tolower(nms), nomatch = 0L)
    } else {
      row.names <- as.integer(row.names)
    }
    stopifnot(length(row.names) == 1)
    
    if (row.names == 0L) return(out)
    
    if(row.names < 1 || row.names > ncol(out)) {
      warning("row.names not set (non-existing field)",
        call. = FALSE)
      return(out)
    }
    rnms <- as.character(out[[row.names]])
    if (anyDuplicated(rnms)) {
      warning("row.names not set (duplicate elements in field)",
        call. = FALSE)
    } else {
      out <- out[, -row.names, drop = F]
      row.names(out) <- rnms
    }
    out
  }
)