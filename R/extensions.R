#' Add useful extension functions
#'
#' These extension functions are written by Liam Healy and made available
#' through the SQLite website (\url{http://www.sqlite.org/contrib}).
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
      call. = FALSE)
  }

  lib_path <- getLoadedDLLs()[["RSQLite"]][["path"]]
  res <- dbGetQuery(db, sprintf("SELECT load_extension('%s')", lib_path))

  invisible(TRUE)
}
