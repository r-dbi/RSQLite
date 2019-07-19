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
#' @return \code{TRUE} if the operator has been loaded.
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
  # replace right-most name of library object (RSQLite) with
  # name of the regexp object, should work across platforms
  lib_path <- sub("(.*)RSQLite([.][a-zA-Z]+?)$", "\\1regexp\\2", lib_path)

  # repeat loading would throw error
  if (is.null(getLoadedDLLs()[["regexp"]][["path"]])) {

    # try to load
    res <- try(
      dbGetQuery(db, sprintf("SELECT load_extension('%s')", lib_path)),
      silent = TRUE)

    # inform user
    invisible(!"try-error" %in% class(res))

  } else {

    # already loaded
    invisible(TRUE)
  }

}
