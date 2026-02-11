#' Configure experimental HTTP VFS behavior (optional)
#'
#' Set conservative, process-wide options for the experimental HTTP/HTTPS VFS.
#' These values are read on first open of a remote database in the current process.
#'
#' Options are stored in environment variables so they also affect C-level code:
#' - `RSQLITE_HTTP_CACHE_MB`: In-memory page cache size in megabytes (default 4).
#' - `RSQLITE_HTTP_PREFETCH_PAGES`: Prefetch this many pages ahead (default 0).
#' - `RSQLITE_HTTP_FALLBACK_FULLDL`: If `TRUE` (default), fall back to full download when the server does not support HTTP Range; if `FALSE`, open will fail.
#'
#' @param cache_size_mb Integer megabytes for in-memory page cache. `NULL` leaves unchanged.
#' @param prefetch_pages Integer pages to prefetch ahead. `NULL` leaves unchanged.
#' @param fallback_full_download Logical; if `TRUE`, allow full-download fallback when Range is not available. `NULL` leaves unchanged.
#' @return A named list of previous values (in R types).
#' @export
#' @examples
#' old <- sqlite_http_config(cache_size_mb = 8, prefetch_pages = 1, fallback_full_download = TRUE)
#' on.exit(do.call(sqlite_http_config, old), add = TRUE)
#' # ... connect with sqlite_remote() ...
sqlite_http_config <- function(
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
