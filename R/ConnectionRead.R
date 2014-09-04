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
#' @param ... Ignored. Needed for compatibility with generic.
#' @examples
#' \dontrun{
#' conn <- dbConnect("SQLite", dbname = "sqlite.db")
#' if(dbExistsTable(con, "fuel_frame")){
#'    dbRemoveTable(conn, "fuel_frame")
#'    dbWriteTable(conn, "fuel_frame", fuel.frame)
#' }
#' if(dbExistsTable(conn, "RESULTS"))
#'    dbWriteTable(conn, "RESULTS", results2000, append = TRUE)
#' else
#'    dbWriteTable(conn, "RESULTS", results2000)
#' 
#' }
#' @export
#' @rdname dbReadTable
setMethod("dbReadTable",
  signature = signature(conn = "SQLiteConnection", name = "character"),
  definition = function(conn, name, ...) sqliteReadTable(conn, name, ...),
  valueClass = "data.frame"
)

#' @export
#' @rdname dbReadTable
#' @param check.names If \code{TRUE}, the default, column names will be
#'   converted to valid R identifiers.
#' @param row.names A string or an index specifying the column in the DBMS table 
#'   to use as \code{row.names} in the output data.frame (a \code{NULL}, 
#'   \code{""}, or 0 specifies that no column should be used as \code{row.names}
#'   in the output.)
#' @param select.cols  A SQL statement (in the form of a character vector of 
#'    length 1) giving the columns to select. E.g. "*" selects all columns, 
#'    "x,y,z" selects three columns named as listed.
sqliteReadTable <- function(con, name, row.names = "row_names", 
                            check.names = TRUE, select.cols="*", ...) {
  out <- dbGetQuery(con, paste("SELECT", select.cols, "FROM", name))

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