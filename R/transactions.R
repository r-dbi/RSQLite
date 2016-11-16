#' @include SQLiteConnection.R
NULL

#' SQLite transaction management.
#'
#' By default, SQLite is in auto-commit mode. `dbBegin()` starts
#' a SQLite transaction and turns auto-commit off. `dbCommit()` and
#' `dbRollback()` commit and rollback the transaction, respectively and turn
#' auto-commit on.
#'
#' @param conn a \code{\linkS4class{SQLiteConnection}} object, produced by
#'   [DBI::dbConnect()]
#' @param name Supply a name to use a named savepoint. This allows you to
#'   nest multiple transaction
#' @param ... Needed for compatibility with generic. Otherwise ignored.
#' @return A boolean, indicating success or failure.
#' @examples
#' library(DBI)
#' con <- dbConnect(SQLite(), ":memory:")
#' dbWriteTable(con, "arrests", datasets::USArrests)
#' dbGetQuery(con, "select count(*) from arrests")
#'
#' dbBegin(con)
#' rs <- dbSendStatement(con, "DELETE from arrests WHERE Murder > 1")
#' dbGetRowsAffected(rs)
#' dbClearResult(rs)
#'
#' dbGetQuery(con, "select count(*) from arrests")
#'
#' dbRollback(con)
#' dbGetQuery(con, "select count(*) from arrests")[1, ]
#'
#' dbBegin(con)
#' rs <- dbSendStatement(con, "DELETE FROM arrests WHERE Murder > 5")
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
#' @name sqlite-transaction
NULL

#' @export
#' @rdname sqlite-transaction
setMethod("dbBegin", "SQLiteConnection", function(conn, name = NULL, ...) {
  if (is.null(name)) {
    dbExecute(conn, "BEGIN")
  } else {
    dbExecute(conn, paste("SAVEPOINT ", name))
  }

  invisible(TRUE)
})

#' @export
#' @rdname sqlite-transaction
setMethod("dbCommit", "SQLiteConnection", function(conn, name = NULL, ...) {
  if (is.null(name)) {
    dbExecute(conn, "COMMIT")
  } else {
    dbExecute(conn, paste("RELEASE SAVEPOINT ", name))
  }

  invisible(TRUE)
})

#' @export
#' @rdname sqlite-transaction
setMethod("dbRollback", "SQLiteConnection", function(conn, name = NULL, ...) {
  if (is.null(name)) {
    dbExecute(conn, "ROLLBACK")
  } else {
    # The ROLLBACK TO command reverts the state of the database back to what it
    # was just after the corresponding SAVEPOINT. Note that unlike that plain
    # ROLLBACK command (without the TO keyword) the ROLLBACK TO command does not
    # cancel the transaction. Instead of cancelling the transaction, the
    # ROLLBACK TO command restarts the transaction again at the beginning. All
    # intervening SAVEPOINTs are canceled, however.
    dbExecute(conn, paste("ROLLBACK TO ", name))
    dbExecute(conn, paste("RELEASE SAVEPOINT ", name))
  }

  invisible(TRUE)
})
