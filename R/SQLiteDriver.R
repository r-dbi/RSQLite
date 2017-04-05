#' @useDynLib RSQLite, .registration = TRUE
#' @importFrom Rcpp sourceCpp
#' @importFrom bit64 integer64
#' @importFrom blob blob
NULL

#' Class SQLiteDriver (and methods)
#'
#' The SQLiteDriver, which is used to select the correct method in
#' [dbConnect()]. See more details in [SQLite()].
#' It is used purely for dispatch and [dbUnloadDriver()] is a null-op.
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
