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

compat_name <- function(name, .name) {
  if (!is.null(.name)) {
    warning("Please use `dbBegin(..., name = \"<savepoint>\")` to specify the name of the savepoint.",
      call. = FALSE
    )
    .name
  } else {
    name
  }
}

get_savepoint_id <- function(name) {
  random_string <- paste(sample(letters, 10, replace = TRUE), collapse = "")
  paste0(name, "_", Sys.getpid(), "_", random_string)
}

sqliteIsTransacting <- function(conn) {
  return(connection_in_transaction(conn@ptr))
}
