#' @include SQLiteConnection.R
#' @include SQLiteDriver.R
NULL

#' Connect to an SQLite database
#'
#' Together, `SQLite()` and `dbConnect()` allow you to connect to
#' a SQLite database file. See [DBI::dbSendQuery()] for how to issue queries
#' and receive results.
#'
#' Connections are automatically cleaned-up after they're deleted and
#' reclaimed by the GC. You can use [DBI::dbDisconnect()] to terminate the
#' connection early, but it will not actually close until all open result
#' sets have been closed (and you'll get a warning message to this effect).
#'
#' @seealso
#' The corresponding generic functions [DBI::dbConnect()] and [DBI::dbDisconnect()].
#'
#' @export
#' @param ... In previous versions, `SQLite()` took arguments. These
#'   have now all been moved to [dbConnect()], and any arguments here
#'   will be ignored with a warning.
#'
#' @return `SQLite()` returns an object of class [SQLiteDriver-class].
#' @import methods DBI
#' @aliases RSQLite RSQLite-package
SQLite <- function(...) {
  if (nargs() > 0) {
    warning("All arguments to RSQLite Driver are ignored.", call. = FALSE)
  }
  new("SQLiteDriver")
}

# From https://www.sqlite.org/c3ref/c_open_autoproxy.html
#' @export
SQLITE_RW <- 0x00000002L

#' @export
SQLITE_RO <- 0x00000001L

#' @export
SQLITE_RWC <- bitwOr(bitwOr(0x00000004L, 0x00000002L), 0x00000040L)

check_vfs <- function(vfs) {
  if (is.null(vfs) || vfs == "") {
    return("")
  }

  if (.Platform[["OS.type"]] == "windows") {
    warning("vfs customization not available on this platform.",
      " Ignoring value: vfs = ", vfs,
      call. = FALSE
    )
    return("")
  }

  match.arg(vfs, c(
    "unix-posix", "unix-afp", "unix-flock", "unix-dotfile",
    "unix-none"
  ))
}

# From the SQLite docs: If the filename is ":memory:", then a private,
# temporary in-memory database is created for the connection. This in-memory
# database will vanish when the database connection is closed. Future versions
# of SQLite might make use of additional special filenames that begin with the
# ":" character. It is recommended that when a database filename actually does
# begin with a ":" character you should prefix the filename with a pathname
# such as "./" to avoid ambiguity.
#
# This function checks for known protocols, or for a colon at the beginning.
is_url_or_special_filename <- function(x) grepl("^(?:file|http|ftp|https|):", x)


#' @import rlang
NULL
