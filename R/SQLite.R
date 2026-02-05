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

#' @description Capability query for optional HTTP VFS support.
#' @export
sqliteHasHttpVFS <- function() {
  # Call C++ helper if registered by cpp11, else FALSE.
  if (!exists("sqlite_has_http_vfs")) return(FALSE)
  ok <- sqlite_has_http_vfs()
  if (isTRUE(ok)) return(TRUE)
  # Try lazy registration via initExtension() on a throwaway connection
  # so that capability can reflect build availability.
  tmp <- NULL
  try({
    tmp <- DBI::dbConnect(SQLite(), ":memory:")
    initExtension(tmp, "http")
  }, silent = TRUE)
  if (!is.null(tmp)) try(DBI::dbDisconnect(tmp), silent = TRUE)
  sqlite_has_http_vfs()
}

#' Experimental HTTP VFS statistics
#'
#' Returns counters collected for HTTP VFS operations in the current process.
#' These values are best-effort and may currently report zeros until
#' global aggregation is implemented.
#'
#' @details Statistics are maintained per R process and reset when the process
#' terminates. Values:
#' * `bytes_fetched`: Total bytes transferred via HTTP GET/Range requests.
#' * `range_requests`: Count of HTTP Range requests performed.
#' * `full_download`: Logical flag; `TRUE` if a fallback full download occurred
#'   for any open in this process.
#'
#' If the HTTP VFS was not compiled in, all zeros (and `FALSE`) are returned.
#'
#' @examples
#' if (sqliteHasHttpVFS()) {
#'   # Hypothetical remote DB (replace with a real URL for actual use):
#'   # old <- sqlite_http_config(cache_size_mb = 8, prefetch_pages = 1)
#'   # on.exit(do.call(sqlite_http_config, old), add = TRUE)
#'   # con <- sqlite_remote("https://example.org/db.sqlite")
#'   # dbGetQuery(con, "SELECT name FROM sqlite_master WHERE type='table'")
#'   stats <- sqliteHttpStats()
#'   str(stats)
#' }
#'
#' @seealso [sqlite_http_config()], [sqlite_remote()], [sqliteHasHttpVFS()]
#'
#' @return A list with elements `bytes_fetched`, `range_requests`, `full_download`.
#' @export
sqliteHttpStats <- function() {
  if (!exists("sqlite_http_stats")) {
    return(list(bytes_fetched = 0L, range_requests = 0L, full_download = FALSE))
  }
  sqlite_http_stats()
}

#' Was HTTP VFS compiled into this build?
#'
#' Returns TRUE if the experimental HTTP/HTTPS virtual file system was compiled
#' in (libcurl detected at build time), FALSE otherwise. This is a compile-time
#' indicator; even if TRUE the VFS might still fail to register at runtime on
#' unusual platforms, in which case `sqliteHasHttpVFS()` is the definitive
#' runtime capability probe.
#'
#' @details The eager registration performed in `.onLoad()` only runs when this
#' function returns TRUE. If FALSE, calls to [sqlite_remote()] will error unless
#' a supported build is installed.
#'
#' @return A logical scalar.
#' @examples
#' sqliteHttpVfsCompiled()
#' @export
sqliteHttpVfsCompiled <- function() {
  isTRUE(tryCatch({
    exists("sqlite_httpvfs_compiled") && sqlite_httpvfs_compiled()
  }, error = function(e) FALSE))
}


#' @import rlang
NULL
