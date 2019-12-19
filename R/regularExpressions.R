#' Add regular expression operator
#'
#' This loads a regular-expression matcher for posix extended regular
#' expressions, as available through the SQLite source code repository
#' (\url{https://sqlite.org/src/raw?filename=ext/misc/regexp.c}).
#'
#' SQLite will then implement the "A regexp B" operator,
#' where A is the string to be matched and B is the regular expression.
#'
#' Note this only affects the specified connection.
#'
#' @return Always \code{TRUE}, invisibly.
#'
#' @param db A \code{\linkS4class{SQLiteConnection}} object to add the
#' regular expression operator into the connection.
#' @export
#' @examples
#' library(DBI)
#' db <- RSQLite::datasetsDb()
#' RSQLite::initRegExp(db)
#'
#' dbGetQuery(db, "SELECT * FROM mtcars WHERE carb REGEXP '[12]'")
#' dbDisconnect(db)
initRegExp <- function(db) {
  if (!db@loadable.extensions) {
    stop("Loadable extensions are not enabled for this db connection",
         call. = FALSE)
  }

  lib_path <- getLoadedDLLs()[["RSQLite"]][["path"]]
  extension_load(db@ptr, lib_path, "sqlite3_regexp_init")

  # always return TRUE after loading
  invisible(TRUE)
}
