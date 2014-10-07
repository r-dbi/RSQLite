#' @include Driver.R
#' @include Connection.R
#' @include Result.R
NULL

#' Determine the SQL Data Type of an R object.
#' 
#' This method is a straight-forward implementation of the corresponding
#' generic function.
#' 
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


#' Check whether an SQLite object is valid or not.
#' 
#' Support function that verifies that the holding a reference to a
#' foreign object is still valid for communicating with the RDBMS
#' 
#' @param dbObj,obj A driver, connection or result.
#' @return A logical scalar.
#' @examples
#' dbIsValid(SQLite())
#' 
#' con <- dbConnect(SQLite())
#' dbIsValid(con)
#' 
#' dbDisconnect(con)
#' dbIsValid(con)
#' @name dbIsValid
NULL

#' @rdname dbIsValid
#' @useDynLib RSQLite rsqlite_driver_valid
#' @export
setMethod("dbIsValid", "SQLiteDriver", function(dbObj) {
  .Call(rsqlite_driver_valid)
})
#' @rdname dbIsValid
#' @useDynLib RSQLite rsqlite_connection_valid
#' @export
setMethod("dbIsValid", "SQLiteConnection", function(dbObj) {
  .Call(rsqlite_connection_valid, dbObj@Id)
})
#' @rdname dbIsValid
#' @useDynLib RSQLite rsqlite_result_valid
#' @export
setMethod("dbIsValid", "SQLiteResult", function(dbObj) {
  .Call(rsqlite_result_valid, dbObj@Id)
})

#' @rdname dbIsValid
#' @export
isIdCurrent <- function(obj) {
  .Deprecated("dbIsValid")
  dbIsValid(obj)
}

check_valid <- function(x) {
  if (dbIsValid(x)) return(TRUE)  
  stop("Expired ", class(x)[1], call. = FALSE)
}
