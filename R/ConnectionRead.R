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
#' @param row.names A string or an index specifying the column in the DBMS table 
#'   to use as \code{row.names} in the output data.frame. Defaults to using the
#'   \code{row_names} column if present. Set to \code{NULL} to never use
#'   row names.
#' @param select.cols  A SQL statement (in the form of a character vector of 
#'    length 1) giving the columns to select. E.g. "*" selects all columns, 
#'    "x,y,z" selects three columns named as listed.
#' @export
#' @examples
#' con <- dbConnect(SQLite())
#' dbWriteTable(con, "mtcars", mtcars)
#' dbReadTable(con, "mtcars")
#' 
#' # Supress row names
#' dbReadTable(con, "mtcars", row.names = FALSE)
#' 
#' dbDisconnect(con)
setMethod("dbReadTable", c("SQLiteConnection", "character"),
  function(conn, name, row.names, check.names = TRUE, 
           select.cols = "*") {
    out <- dbGetQuery(conn, paste("SELECT", select.cols, "FROM", name))
    
    if (check.names) {
      names(out) <- make.names(names(out), unique = TRUE)
    }
    
    row.names <- rownames_column(out, row.names)
    if (is.null(row.names)) return(out)
    
    rnms <- as.character(out[[row.names]])
    if (anyDuplicated(rnms)) {
      warning("row.names not set (duplicate elements in field)", call. = FALSE)
    } else {
      out <- out[, -row.names, drop = F]
      row.names(out) <- rnms
    }
    out
  }
)

# Figure out which column to 
rownames_column <- function(df, row.names) {
  if (missing(row.names)) {
    if (!"row_names" %in% names(df)) {
      return(NULL)
    }

    row.names <- "row_names"
  } 
  
  if (is.null(row.names) || identical(row.names, FALSE)) {
    NULL
  } else if (is.character(row.names)) {
    if (!(row.names %in% names(df))) {
      stop("Column ", row.names, " not present in output", call. = FALSE)
    }
    match(row.names, names(df))
  } else if (is.numeric(row.names)) {
    if (row.names == 0) return(NULL)
    if (row.names < 0 || row.names > ncol(df)) {
      stop("Column ", row.names, " not present in output", call. = FALSE)
    }
    row.names
  } else {
    stop("Unknown specification for row.names")
  }
}