#' Class SQLiteResultArrow (and methods)
#'
#' SQLiteResultArrow objects are created by [DBI::dbSendQueryArrow()],
#' and encapsulate the result of an SQL query whose rows are fetched as Arrow arrays.
#' They are a superclass of the [DBIResultArrow-class][DBI::DBIResultArrow-class] class.
#' The "Usage" section lists the class methods overridden by \pkg{RSQLite}.
#' Every other method delegates to the [SQLiteResult-class] object in the `result` slot.
#'
#' @seealso
#' The corresponding generic functions
#' [DBI::dbFetchArrow()], [DBI::dbFetchArrowChunk()], [DBI::dbBindArrow()],
#' [DBI::dbClearResult()], and [DBI::dbHasCompleted()],
#' and the type mappings in [sqlite-arrow].
#'
#' @export
#' @keywords internal
#' @include SQLiteResult.R
setClass("SQLiteResultArrow",
  contains = "DBIResultArrow",
  slots = list(
    result = "SQLiteResult"
  )
)

SQLiteResultArrow <- function(result) {
  new("SQLiteResultArrow", result = result)
}
