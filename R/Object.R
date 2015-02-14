#' @include Driver.R
#' @include Connection.R
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
