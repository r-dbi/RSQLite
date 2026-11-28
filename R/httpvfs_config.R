#' Configure experimental HTTP VFS behavior (optional)
#'
#' @description
#' lifecycle::badge("experimental")
#'
#' Set conservative, process-wide options for the experimental HTTP/HTTPS VFS.
#' These values are read each time a remote database is opened.
#'
#' @details
#' Options are stored in environment variables so they also affect C-level code:
#' - `RSQLITE_HTTP_CACHE_MB`: In-memory page cache size in megabytes (default 4).
#' - `RSQLITE_HTTP_PREFETCH_PAGES`: Prefetch this many pages ahead (default 0).
#' - `RSQLITE_HTTP_FALLBACK_FULLDL`: If `TRUE` (default), fall back to full download when the server does not support HTTP Range;
#'   if `FALSE`, open will fail.
#'
#' Two more variables, without an argument here, limit how long a transfer may wait:
#' - `RSQLITE_HTTP_CONNECT_TIMEOUT`: Seconds to wait for a connection to the server (default 30).
#' - `RSQLITE_HTTP_STALL_TIMEOUT`: Seconds a transfer may receive less than one byte per second before it is aborted (default 60).
#'
#' Only whole numbers of seconds of at least 1 are honored, in any notation such as `120` or `1e+05`.
#' Larger values than 2147483 seconds (about 25 days) are capped,
#' and libcurl 8.19.0 or later caps the stall timeout at 65535 seconds (about 18 hours).
#' Anything else uses the default.
#'
#' An aborted transfer, or one interrupted by the user, fails the open or the query with an SQLite error.
#'
#' @param cache_size_mb Integer megabytes for in-memory page cache.
#'   `NULL` leaves unchanged.
#' @param prefetch_pages Integer pages to prefetch ahead.
#'   `NULL` leaves unchanged.
#' @param fallback_full_download Logical; if `TRUE`, allow full-download fallback when Range is not available.
#'   `NULL` leaves unchanged.
#' @return A named list of previous values (in R types).
#' @export
#' @examples
#' old <- sqliteHttpConfig(cache_size_mb = 8, prefetch_pages = 1, fallback_full_download = TRUE)
#' on.exit(do.call(sqliteHttpConfig, old), add = TRUE)
#' # ... connect with sqliteRemote() ...
sqliteHttpConfig <- function(
  cache_size_mb = NULL,
  prefetch_pages = NULL,
  fallback_full_download = NULL
) {
  stopifnot(
    is.null(cache_size_mb) ||
      (is.numeric(cache_size_mb) && length(cache_size_mb) == 1L)
  )
  stopifnot(
    is.null(prefetch_pages) ||
      (is.numeric(prefetch_pages) && length(prefetch_pages) == 1L)
  )
  stopifnot(
    is.null(fallback_full_download) || is.logical(fallback_full_download)
  )

  prev <- list(
    cache_size_mb = as.integer(Sys.getenv(
      "RSQLITE_HTTP_CACHE_MB",
      unset = "4"
    )),
    prefetch_pages = as.integer(Sys.getenv(
      "RSQLITE_HTTP_PREFETCH_PAGES",
      unset = "0"
    )),
    fallback_full_download = as.logical(
      tolower(Sys.getenv(
        "RSQLITE_HTTP_FALLBACK_FULLDL",
        unset = "1"
      )) %in%
        c("1", "true", "yes")
    )
  )

  if (!is.null(cache_size_mb)) {
    Sys.setenv(RSQLITE_HTTP_CACHE_MB = as.integer(cache_size_mb))
  }
  if (!is.null(prefetch_pages)) {
    Sys.setenv(RSQLITE_HTTP_PREFETCH_PAGES = as.integer(prefetch_pages))
  }
  if (!is.null(fallback_full_download)) {
    Sys.setenv(
      RSQLITE_HTTP_FALLBACK_FULLDL = if (isTRUE(fallback_full_download)) {
        "1"
      } else {
        "0"
      }
    )
  }

  prev
}
