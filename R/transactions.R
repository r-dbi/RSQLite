#' @include SQLiteConnection.R
NULL

#' SQLite transaction management
#'
#' By default, SQLite is in auto-commit mode. `dbBegin()` starts
#' a SQLite transaction and turns auto-commit off. `dbCommit()` and
#' `dbRollback()` commit and rollback the transaction, respectively and turn
#' auto-commit on.
#' [DBI::dbWithTransaction()] is a convenient wrapper that makes sure that
#' `dbCommit()` or `dbRollback()` is called.
#'
#' @seealso
#' The corresponding generic functions [DBI::dbBegin()], [DBI::dbCommit()],
#' and [DBI::dbRollback()].
#'
#' @param conn a \code{\linkS4class{SQLiteConnection}} object, produced by
#'   [DBI::dbConnect()]
#' @param ... Needed for compatibility with generic. Otherwise ignored.
#' @param name Supply a name to use a named savepoint. This allows you to
#'   nest multiple transaction
#' @param .name For backward compatibility, do not use.
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
#' dbBegin(con, name = "a")
#' dbBegin(con, name = "b")
#' dbRollback(con, name = "b")
#' dbCommit(con, name = "a")
#'
#' dbDisconnect(con)
#' @name sqlite-transaction
NULL

#' @export
#' @rdname sqlite-transaction
setMethod("dbBegin", "SQLiteConnection", function(conn, .name = NULL, ..., name = NULL) {
  name <- compat_name(name, .name)
  if (is.null(name)) {
    dbExecute(conn, "BEGIN")
  } else {
    dbExecute(conn, paste("SAVEPOINT ", name))
  }

  invisible(TRUE)
})

#' @export
#' @rdname sqlite-transaction
setMethod("dbCommit", "SQLiteConnection", function(conn, .name = NULL, ..., name = NULL) {
  name <- compat_name(name, .name)
  if (is.null(name)) {
    dbExecute(conn, "COMMIT")
  } else {
    dbExecute(conn, paste("RELEASE SAVEPOINT ", name))
  }

  invisible(TRUE)
})

#' @export
#' @rdname sqlite-transaction
setMethod("dbRollback", "SQLiteConnection", function(conn, .name = NULL, ..., name = NULL) {
  name <- compat_name(name, .name)
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

compat_name <- function(name, .name) {
  if (!is.null(.name)) {
    warning("Please use `dbBegin(..., name = \"<savepoint>\")` to specify the name of the savepoint.",
      call. = FALSE)
    .name
  } else {
    name
  }
}
