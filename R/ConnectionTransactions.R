#' @include ConnectionTransactions.R
NULL

# Transactions -----------------------------------------------------------------

#' SQLite transaction management.
#' 
#' By default, SQLite is in auto-commit mode. \code{dbBeginTransaction} starts
#' a SQLite transaction and turns auto-commit off. \code{dbCommit} and
#' \code{dbRollback} commit and rollback the transaction, respectively and turn
#' auto-commit on.
#' 
#' @param conn a \code{\linkS4class{SQLiteConnection}} object, produced by
#'   \code{\link[DBI]{dbConnect}}
#' @param ... Ignored. Needed for compatibility with generic.
#' @examples
#' con <- dbConnect(SQLite(), dbname = tempfile())
#' data(USArrests)
#' dbWriteTable(con, "arrests", USArrests)
#' dbGetQuery(con, "select count(*) from arrests")[1, ]
#' 
#' dbBeginTransaction(con)
#' rs <- dbSendQuery(con, "DELETE from arrests WHERE Murder > 1")
#' do_commit <- if (dbGetInfo(rs)[["rowsAffected"]] > 40) FALSE else TRUE
#' dbClearResult(rs)
#' dbGetQuery(con, "select count(*) from arrests")[1, ]
#' if (!do_commit) dbRollback(con)
#' dbGetQuery(con, "select count(*) from arrests")[1, ]
#' 
#' dbBeginTransaction(con)
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
setMethod("dbCommit", "SQLiteConnection",
  definition = function(conn, ...) sqliteTransactionStatement(conn, "COMMIT")
)

setMethod("dbRollback", "SQLiteConnection",
  definition = function(conn, ...) {
    rsList <- dbListResults(conn)
    if (length(rsList))
      dbClearResult(rsList[[1]])
    sqliteTransactionStatement(conn, "ROLLBACK")
  }
)

#' @export
#' @rdname transactions
setMethod("dbBeginTransaction", "SQLiteConnection",
  definition = function(conn, ...) sqliteTransactionStatement(conn, "BEGIN")
)

sqliteTransactionStatement <- function(con, statement) {
  ## are there resultSets pending on con?
  if(length(dbListResults(con)) > 0){
    res <- dbListResults(con)[[1]]
    if(!dbHasCompleted(res)){
      stop("connection with pending rows, close resultSet before continuing")
    }
    dbClearResult(res)
  }
  
  rc <- try(dbGetQuery(con, statement), silent = TRUE)
  !inherits(rc, ErrorClass)
}
