#' SQLite transaction management.
#' 
#' By default, SQLite is in auto-commit mode. \code{dbBegin} starts
#' a SQLite transaction and turns auto-commit off. \code{dbCommit} and
#' \code{dbRollback} commit and rollback the transaction, respectively and turn
#' auto-commit on.
#' 
#' @param conn a \code{\linkS4class{SQLiteConnection}} object, produced by
#'   \code{\link[DBI]{dbConnect}}
#' @param name Supply a name to use a named savepoint. This allows you to
#'   nest multiple transaction
#' @return A boolean, indicating success or failure.
#' @examples
#' con <- dbConnect(SQLite(), ":memory:")
#' dbWriteTable(con, "arrests", datasets::USArrests)
#' dbGetQuery(con, "select count(*) from arrests")
#' 
#' dbBegin(con)
#' rs <- dbSendQuery(con, "DELETE from arrests WHERE Murder > 1")
#' dbGetRowsAffected(rs)
#' dbClearResult(rs)
#' 
#' dbGetQuery(con, "select count(*) from arrests")
#' 
#' dbRollback(con)
#' dbGetQuery(con, "select count(*) from arrests")[1, ]
#' 
#' dbBegin(con)
#' rs <- dbSendQuery(con, "DELETE FROM arrests WHERE Murder > 5")
#' dbClearResult(rs)
#' dbCommit(con)
#' dbGetQuery(con, "SELECT count(*) FROM arrests")[1, ]
#' 
#' # Named savepoints can be nested --------------------------------------------
#' dbBegin(con, "a")
#' dbBegin(con, "b")
#' dbRollback(con, "b")
#' dbCommit(con, "a")
#' 
#' dbDisconnect(con)
#' @name transactions
NULL

#' @export
#' @rdname transactions
setMethod("dbBegin", "SQLiteConnection", function(conn, name = NULL) {
  if (is.null(name)) {
    dbGetQuery(conn, "BEGIN")  
  } else {
    dbGetQuery(conn, paste("SAVEPOINT ", name))
  }
  
  TRUE
})

#' @export
#' @rdname transactions
setMethod("dbCommit", "SQLiteConnection", function(conn, name = NULL) {
  if (is.null(name)) {
    dbGetQuery(conn, "COMMIT")
  } else {
    dbGetQuery(conn, paste("RELEASE SAVEPOINT ", name))
  }
  
  TRUE
})

#' @export
#' @rdname transactions
setMethod("dbRollback", "SQLiteConnection", function(conn, name = NULL) {
  if (is.null(name)) {
    dbGetQuery(conn, "ROLLBACK")
  } else {
    dbGetQuery(conn, paste("ROLLBACK TO ", name))
  }
  TRUE
})
