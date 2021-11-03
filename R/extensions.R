#' Add useful extension functions
#'
#' These extension functions are written by Liam Healy and made available
#' through the SQLite website (\url{https://www.sqlite.org/contrib}).
#'
#' @section Available extension functions:
#'
#' \describe{
#' \item{Math functions}{acos, acosh, asin, asinh, atan, atan2, atanh, atn2,
#'   ceil, cos, cosh, cot, coth, degrees, difference, exp, floor, log, log10,
#'   pi, power, radians, sign, sin, sinh, sqrt, square, tan, tanh}
#' \item{String functions}{charindex, leftstr, ltrim, padc, padl, padr, proper,
#'   replace, replicate, reverse, rightstr, rtrim, strfilter, trim}
#' \item{Aggregate functions}{stdev, variance, mode, median, lower_quartile,
#'   upper_quartile}
#' }
#' @param db A \code{\linkS4class{SQLiteConnection}} object to load these extensions into.
#' @export
#' @examples
#' library(DBI)
#' db <- RSQLite::datasetsDb()
#' RSQLite::initExtension(db)
#'
#' dbGetQuery(db, "SELECT stdev(mpg) FROM mtcars")
#' sd(mtcars$mpg)
#' dbDisconnect(db)
initExtension <- function(db) {
  if (!db@loadable.extensions) {
    stop("Loadable extensions are not enabled for this db connection",
      call. = FALSE
    )
  }

  extension_load(db@ptr, get_lib_path(), "sqlite3_math_init")

  invisible(TRUE)
}

#' Add `generate_series()` function
#'
#' This loads the table-valued function `generate_series()`,
#' as available through the SQLite source code repository
#' (\url{https://sqlite.org/src/raw?filename=ext/misc/series.c}).
#'
#' @param db A \code{\linkS4class{SQLiteConnection}} object to load these extensions into.
#'
#' @return Always \code{TRUE}, invisibly.
#' @export
#' @examples
#' library(DBI)
#' db <- RSQLite::datasetsDb()
#' RSQLite::initSeries(db)
#'
#' dbGetQuery(db, "SELECT value FROM generate_series(0, 20, 5);")
#' dbDisconnect(db)
initSeries <- function(db) {
  if (!db@loadable.extensions) {
    stop("Loadable extensions are not enabled for this db connection",
      call. = FALSE
    )
  }

  extension_load(db@ptr, get_lib_path(), "sqlite3_series_init")

  invisible(TRUE)
}

get_lib_path <- function() {
  lib_path <- getLoadedDLLs()[["RSQLite"]][["path"]]
  enc2utf8(lib_path)
}
