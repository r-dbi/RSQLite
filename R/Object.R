#' @include Driver.R
#' @include Connection.R
#' @include Result.R
NULL

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
setMethod("dbDataType", "SQLiteConnection", function(dbObj, obj, ...) {
  sqliteDataType(obj, ...)
})

#' @rdname dbDataType-SQLiteConnection-method
#' @export
setMethod("dbDataType", "SQLiteDriver", function(dbObj, obj, ...) {
  sqliteDataType(obj, ...)
})

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


#' Check whether an SQLite object is valid or not
#' 
#' Support function that verifies that an dbObjectId holding a reference to a
#' foreign object is still valid for communicating with the RDBMS
#' 
#' \code{dbObjectId} are R/S-Plus remote references to foreign (C code)
#' objects. This introduces differences to the object's semantics such as
#' persistence (e.g., connections may be closed unexpectedly), thus this
#' function provides a minimal verification to ensure that the foreign object
#' being referenced can be contacted.
#' 
#' @param obj any \code{dbObjectId} (e.g., \code{dbDriver},
#' \code{dbConnection}, \code{dbResult}).
#' @return a logical scalar.
#' @examples
#' \dontrun{
#' cursor <- dbSendQuery(con, sql.statement)
#' isIdCurrent(cursor)
#' }
#' 
#' @export isIdCurrent
#' @useDynLib RSQLite RS_DBI_validHandle
"isIdCurrent" <- function(obj) { 
  .Call(RS_DBI_validHandle, obj@Id)
}
