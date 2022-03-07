#' Add regular expression operator
#'
#' Forwarded to `initExtension(db, "regexp")` .
#'
#' @return Always \code{TRUE}, invisibly.
#'
#' @param db A \code{\linkS4class{SQLiteConnection}} object to add the
#' regular expression operator into the connection.
#' @export
#' @keywords internal
initRegExp <- function(db) {
  initExtension(db, "regexp")
}
