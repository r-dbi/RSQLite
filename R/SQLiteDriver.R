#' @useDynLib RSQLite, .registration = TRUE
#' @importFrom Rcpp sourceCpp
#' @importFrom bit64 integer64 is.integer64
#' @importFrom blob blob
NULL

#' Class SQLiteDriver (and methods)
#'
#' SQLiteDriver objects are created by [SQLite()], and used to select the
#' correct method in [dbConnect()].
#' They are a superclass of the [DBIDriver-class] class,
#' and used purely for dispatch.
#' The "Usage" section lists the class methods overridden by \pkg{RSQLite}.
#' The [dbUnloadDriver()] method is a null-op.
#'
#' @keywords internal
#' @export
setClass("SQLiteDriver",
  contains = "DBIDriver"
)

#' @rdname SQLiteDriver-class
#' @export
setMethod("dbDataType", "SQLiteDriver", function(dbObj, obj, ...) {
  if (is.factor(obj)) return("TEXT")
  if (is.data.frame(obj)) return(callNextMethod(dbObj, obj))
  if (is.integer64(obj)) return("INTEGER")

  switch(typeof(obj),
    integer = "INTEGER",
    double = "REAL",
    character = "TEXT",
    logical = "INTEGER",
    list = "BLOB",
    raw = "TEXT",
    stop("Unsupported type", call. = FALSE)
  )
})

#' @rdname SQLiteDriver-class
#' @export
setMethod("dbIsValid", "SQLiteDriver", function(dbObj, ...) {
  TRUE
})

#' @rdname SQLiteDriver-class
#' @export
setMethod("dbUnloadDriver", "SQLiteDriver", function(drv, ...) {
  invisible(TRUE)
})
