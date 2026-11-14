#' @useDynLib RSQLite, .registration = TRUE
#' @importFrom bit64 integer64 is.integer64
#' @importFrom blob blob
NULL

#' Class SQLiteDriver (and methods)
#'
#' SQLiteDriver objects are created by [SQLite()],
#' and used to select the correct method in [dbConnect()].
#' They are a superclass of the [DBIDriver-class] class,
#' and used purely for dispatch.
#' The "Usage" section lists the class methods overridden by \pkg{RSQLite}.
#' The [dbUnloadDriver()] method is a null-op.
#'
#' @return
#' `dbDataType()` returns a character vector of SQL data types.
#' `dbGetInfo()` returns a list with elements `driver.version` and `client.version`.
#' `dbIsValid()` always returns `TRUE`.
#' `dbUnloadDriver()` returns `TRUE`, invisibly.
#'
#' @keywords internal
#' @export
setClass("SQLiteDriver",
  contains = "DBIDriver"
)

# Set during installation time for the correct library
PACKAGE_VERSION <- utils::packageVersion(utils::packageName())
