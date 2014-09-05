#' Summary methods
#' 
#' @keywords internal
#' @name summary
#' @examples
#' summary(SQLite())
#' 
#' con <- dbConnect(SQLite())
#' summary(con)
#' 
#' dbWriteTable(con, "mtcars", mtcars)
#' rs <- dbSendQuery(con, "SELECT * FROM mtcars")
#' summary(rs)
#' 
#' dbClearResults(rs)
#' dbDisconnect(con)
NULL

setGeneric("summary")

#' @export
#' 
#' @param verbose Show extra information.
#' @rdname summary
setMethod("summary", "SQLiteDriver", function(object) {
  cat("<SQLiteDriver>\n")
  if (!isIdCurrent(object)) {
    cat("EXPIRED\n")
  } else {
    info <- dbGetInfo(object)
    cat("  Driver name:       ", info$drvName, "\n", sep = "")
    cat("  Max connections:   ", info$length, "\n", sep = "")
    cat("  Conn. processed:   ", info$counter, "\n", sep = "")
    cat("  Records per fetch: ", info$fetch_default_rec, "\n", sep = "")
    cat("  SQLite version:    ", info$clientVersion, "\n", sep = "")
    cat("  DBI version:       ", as.character(packageVersion("DBI")), "\n", sep = "")
    cat("  Open connections:  ", info$num_con, "\n", sep = "")
    cat("  Shared Cache:      ", info$shared_cache, "\n", sep = "")
  }
  
  invisible(NULL)
})

#' @export
#' @rdname summary
setMethod("summary", "SQLiteConnection", function(object) {
  cat("<SQLiteConnection>\n")
  if(!isIdCurrent(object)){
    cat("EXPIRED")
  } else {
    info <- dbGetInfo(object)
    cat("  SQLite version:      ", info$serverVersion, "\n", sep = "")
    cat("  Database name:       ", info$dbname, "\n", sep = "")
    cat("  Loadable extensions: ", info$loadableExtensions, "\n", sep = "")
    cat("  File open flags:     ", info$falgs, "\n", sep = "")
    cat("  VFS:                 ", info$vfs, "\n", sep = "")
  }

  invisible(NULL)
})

#' @export
#' @rdname summary
setMethod("summary", "SQLiteResult", function(object) {
  cat("<SQLiteResult>\n")
  if(!isIdCurrent(object)){
    cat("EXPIRED")
  } else {  
    cat("  Statement:     ", dbGetStatement(object), "\n", sep = "")
    cat("  Has completed? ", if(dbHasCompleted(object)) "yes" else "no", "\n", sep = "")
    cat("  Affected rows: ", dbGetRowsAffected(object), "\n", sep = "")
  }
  invisible(NULL)  
})


setMethod("show", "SQLiteDriver", function(object) {
  cat("<SQLiteDriver>\n")
})
setMethod("show", "SQLiteConnection", function(object) {
  cat("<SQLiteConnection>\n")
})
setMethod("show", "SQLiteResult", function(object) {
  cat("<SQLiteResult>\n")
})