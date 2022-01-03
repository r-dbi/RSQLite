#' @rdname SQLiteDriver-class
#' @usage NULL
dbDataType_SQLiteDriver <- function(dbObj, obj, ..., extended_types = FALSE) {
  if (is.factor(obj)) {
    return("TEXT")
  }
  if (is.data.frame(obj)) {
    return(callNextMethod(dbObj, obj))
  }
  if (is.integer64(obj)) {
    return("INTEGER")
  }
  if (extended_types && methods::is(obj, "Date")) {
    return("DATE")
  }
  if (extended_types && methods::is(obj, "POSIXct")) {
    return("TIMESTAMP")
  }
  if (extended_types && methods::is(obj, "hms")) {
    return("TIME")
  }

  switch(typeof(obj),
    integer = "INTEGER",
    double = "REAL",
    character = "TEXT",
    logical = "INTEGER",
    list = "BLOB",
    raw = "TEXT",
    stop("Unsupported type", call. = FALSE)
  )
}
#' @rdname SQLiteDriver-class
#' @export
setMethod("dbDataType", "SQLiteDriver", dbDataType_SQLiteDriver)
