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
#' dbDataType(SQLite(), 1)
#' dbDataType(SQLite(), 1L)
#' dbDataType(SQLite(), "1")
#' dbDataType(SQLite(), TRUE)
#' dbDataType(SQLite(), list())
#' 
#' sapply(datasets::quakes, dbDataType, dbObj = SQLite())
#' @export
setMethod("dbDataType", "SQLiteConnection", function(dbObj, obj, ...) {
  sqliteDataType(SQLite(), ...)
})

#' @rdname dbDataType-SQLiteConnection-method
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
#' @export
setMethod("dbIsValid", "SQLiteDriver", function(dbObj) {
  TRUE
})
#' @rdname dbIsValid
#' @export
setMethod("dbIsValid", "SQLiteConnection", function(dbObj) {
  rsqlite_is_valid(dbObj@ptr)
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
