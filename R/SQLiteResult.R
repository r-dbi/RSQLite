#' Class SQLiteResult
#' 
#' SQLite's query results class.  This classes encapsulates the result of an
#' SQL statement (either \code{select} or not).
#' 
#' @export
#' @keywords internal
setClass("SQLiteResult", 
  contains = "DBIResult",
  slots = list(
    sql = "character",
    ptr = "externalptr"
  )
)

#' @rdname SQLiteResult-class
#' @export
setMethod("dbIsValid", "SQLiteResult", function(dbObj) {
  rsqlite_result_valid(dbObj@ptr)
})

#' @rdname SQLiteResult-class
#' @export
setMethod("show", "SQLiteResult", function(object) {
  cat("<SQLiteResult>\n")
  if(!dbIsValid(object)){
    cat("EXPIRED\n")
  } else {  
    cat("  SQL  ", dbGetStatement(object), "\n", sep = "")
    
    done <- if (dbHasCompleted(object)) "complete" else "incomplete"
    cat("  ROWS Fetched: ", dbGetRowCount(object), " [", done, "]\n", sep = "")
    cat("       Changed: ", dbGetRowsAffected(object), "\n", sep = "")
  }
  invisible(NULL)  
})

