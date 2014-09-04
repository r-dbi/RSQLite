#' @include ConnectionTransactions.R
NULL

# Transactions -----------------------------------------------------------------

#' SQLite transaction management.
#' 
#' By default, SQLite is in auto-commit mode. \code{dbBegin} starts
#' a SQLite transaction and turns auto-commit off. \code{dbCommit} and
#' \code{dbRollback} commit and rollback the transaction, respectively and turn
#' auto-commit on.
#' 
#' @param conn a \code{\linkS4class{SQLiteConnection}} object, produced by
#'   \code{\link[DBI]{dbConnect}}
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
#' dbDisconnect(con)
#' @name transactions
NULL

#' @export
#' @rdname transactions
setMethod("dbBegin", "SQLiteConnection", function(conn) {
  dbGetQuery(conn, "BEGIN")
  TRUE
})

#' @export
#' @rdname transactions
setMethod("dbCommit", "SQLiteConnection", function(conn) {
  dbGetQuery(conn, "COMMIT")
  TRUE
})

#' @export
#' @rdname transactions
setMethod("dbRollback", "SQLiteConnection", function(conn) {
  dbGetQuery(conn, "ROLLBACK")
  TRUE
})
