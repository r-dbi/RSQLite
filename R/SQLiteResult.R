#' Class SQLiteResult (and methods)
#'
#' SQLiteDriver objects are created by [dbSendQuery()] or [dbSendStatement()],
#' and encapsulate the result of an SQL statement (either `SELECT` or not).
#' They are a superclass of the [DBIResult-class] class.
#' The "Usage" section lists the class methods overridden by \pkg{RSQLite}.
#'
#' @seealso
#' The corresponding generic functions
#' [DBI::dbFetch()], [DBI::dbClearResult()], and [DBI::dbBind()],
#' [DBI::dbColumnInfo()], [DBI::dbGetRowsAffected()], [DBI::dbGetRowCount()],
#' [DBI::dbHasCompleted()], and [DBI::dbGetStatement()].
#'
#' @return
#' `dbBind()` returns the result object, invisibly.
#' `dbClearResult()` returns `TRUE`, invisibly.
#' `dbColumnInfo()` and `dbFetch()` return a data frame.
#' `dbGetRowCount()` and `dbGetRowsAffected()` return a numeric scalar.
#' `dbGetStatement()` returns a character string.
#' `dbHasCompleted()` and `dbIsValid()` return a logical scalar.
#'
#' @export
#' @keywords internal
setClass("SQLiteResult",
  contains = "DBIResult",
  slots = list(
    sql = "character",
    ptr = "externalptr",
    conn = "SQLiteConnection",
    bigint = "character"
  )
)
