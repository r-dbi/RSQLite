#' @include dbObjectId.R
NULL

#' Class SQLiteObject
#' 
#' Base class for all SQLite-specific DBI classes
#' 
#' @docType class
#' @import methods
#' @import DBI
#' @useDynLib RSQLite
#' @export
setClass("SQLiteObject", representation("DBIObject", "dbObjectId", "VIRTUAL"))

#' Determine the SQL Data Type of an R object.
#' 
#' This method is a straight-forward implementation of the corresponding
#' generic function.
#' 
#' @docType methods
#' @param dbObj a \code{SQLiteDriver} object,
#' @param obj an R object whose SQL type we want to determine.
#' @param ... Needed for compatibility with generic. Otherwise ignored.
#' @examples
#' data(quakes)
#' drv <- SQLite()
#'
#' sapply(quakes, function(x) dbDataType(drv, x))
#' 
#' dbDataType(drv, 1)
#' dbDataType(drv, as.integer(1))
#' dbDataType(drv, "1")
#' dbDataType(drv, charToRaw("1"))
#' @export
setMethod("dbDataType", "SQLiteObject",
  definition = function(dbObj, obj, ...) sqliteDataType(obj, ...),
  valueClass = "character"
)

sqliteDataType <- function(obj, ...) {
  rs.class <- data.class(obj)
  rs.mode <- storage.mode(obj)
  switch(rs.class,
    numeric = if (rs.mode=="integer") "INTEGER" else "REAL",
    character = "TEXT",
    logical = "INTEGER",
    factor = "TEXT",
    ordered = "TEXT",
    ## list maps to BLOB. Although not checked, the list must
    ## either be empty or contain only raw vectors or NULLs.
    list = "BLOB",
    ## attempt to store obj according to its storage mode if it has
    ## an unrecognized class.
    switch(rs.mode,
      integer = "INTEGER",
      double = "REAL",
      ## you'll get this if class is AsIs for a list column
      ## within a data.frame
      list = if (rs.class == "AsIs") "BLOB" else "TEXT",
      "TEXT"))
}


#' Make R/S-Plus identifiers into legal SQL identifiers
#' 
#' These methods are straight-forward implementations of the corresponding
#' generic functions.
#' 
#' @docType methods
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
  signature(dbObj="SQLiteObject", snames = "character"),
  definition = function(dbObj, snames, keywords, unique, allow.keywords, ...){
    make.db.names.default(snames, keywords, unique, allow.keywords)
  },
  valueClass = "character"
)

#' @export
#' @rdname make.db.names-SQLiteObject-character-method
setMethod("SQLKeywords", "SQLiteObject",
  definition = function(dbObj, ...) .SQL92Keywords,
  valueClass = "character"
)

#' @export
#' @rdname make.db.names-SQLiteObject-character-method
#' @param name a character vector of SQL identifiers we want to check against
#'   keywords from the DBMS. 
#' @param keywords a character vector with SQL keywords, namely 
#'   \code{.SQL92Keywords} defined in the \code{DBI} package.
#' @param case a character string specifying whether to make the comparison 
#'   as lower case, upper case, or any of the two.  it defaults to \code{"any"}.
setMethod("isSQLKeyword",
  signature(dbObj="SQLiteObject", name="character"),
  definition = function(dbObj, name, keywords, case, ...){
    isSQLKeyword.default(name, keywords = .SQL92Keywords, case)
  },
  valueClass = "character"
)
