#' @include Connection.R
NULL

#' Make R/S-Plus identifiers into legal SQL identifiers
#' 
#' These methods are straight-forward implementations of the corresponding
#' generic functions.
#' 
#' @param dbObj any SQLite object (e.g., \code{SQLiteDriver}).
#' @param snames a character vector of R identifiers (symbols) from which to 
#'   make SQL identifiers.
#' @param unique logical describing whether the resulting set of SQL names 
#'   should be unique.  The default is \code{TRUE}. Following the SQL 92 
#'   standard, uniqueness of SQL identifiers is determined regardless of whether 
#'   letters are upper or lower case.
#' @param allow.keywords logical describing whether SQL keywords should be
#'   allowed in the resulting set of SQL names.  The default is \code{TRUE}.
#' @param ... Not used. Included for compatiblity with generic.
#' @keywords internal
#' @examples
#' \dontrun{
#' # This example shows how we could export a bunch of data.frames
#' # into tables on a remote database.
#' 
#' con <- dbConnect("SQLite", dbname = "sqlite.db")
#' 
#' export <- c("trantime.email", "trantime.print", "round.trip.time.email")
#' tabs <- make.db.names(con, export, unique = TRUE, allow.keywords = TRUE)
#' 
#' for(i in seq_along(export) )
#'    dbWriteTable(con, name = tabs[i],  get(export[i]))
#' }
#' 
#' @export
setMethod("make.db.names",
  signature(dbObj="SQLiteConnection", snames = "character"),
  function(dbObj, snames, keywords, unique, allow.keywords, ...) {
    make.db.names.default(snames, keywords, unique, allow.keywords)
  }
)

#' @export
#' @rdname make.db.names-SQLiteConnection-character-method
setMethod("SQLKeywords", "SQLiteConnection", function(dbObj, ...) {
  .SQL92Keywords
})

#' @export
#' @rdname make.db.names-SQLiteConnection-character-method
#' @param name a character vector of SQL identifiers we want to check against
#'   keywords from the DBMS. 
#' @param keywords a character vector with SQL keywords, namely 
#'   \code{.SQL92Keywords} defined in the \code{DBI} package.
#' @param case a character string specifying whether to make the comparison 
#'   as lower case, upper case, or any of the two.  it defaults to \code{"any"}.
setMethod("isSQLKeyword",
  signature(dbObj="SQLiteConnection", name="character"),
  function(dbObj, name, keywords, case, ...) {
    isSQLKeyword.default(name, keywords = .SQL92Keywords, case)
  }
)
