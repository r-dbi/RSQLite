#' Convenience helper for opening remote SQLite databases over HTTP/HTTPS
#'
#' Constructs a URI filename and sets the appropriate VFS and immutable flags.
#' Requires the optional http extension to be available; see [sqliteHasHttpVFS()].
#'
#' @param url Remote HTTP/HTTPS URL to a SQLite database file.
#' @param immutable Logical, append `immutable=1` to the URI.
#' @param ... Passed through to [DBI::dbConnect()].
#' @return A [SQLiteConnection-class] object.
#' @export
#' @examples
#' if (sqliteHasHttpVFS()) {
#'   # Example (will fail unless URL points to a real SQLite file, shown for syntax only):
#'   # con <- sqlite_remote("https://example.org/db.sqlite")
#'   # dbGetQuery(con, "SELECT name FROM sqlite_master WHERE type='table'")
#'   # dbDisconnect(con)
#' }
sqlite_remote <- function(url, immutable = TRUE, ...) {
	stopifnot(is.character(url), length(url) == 1L)
	if (!grepl("^https?://", url)) {
		stop("url must begin with http:// or https://", call. = FALSE)
	}
	# SQLite URI parameters are introduced after '?'. If we appended them directly
	# to the HTTP URL, they would become part of the HTTP request and can cause
	# a 404 on static hosts. Instead, wrap the URL in a SQLite file: URI.
	if (grepl("[?#]", url)) {
		stop("url must not contain a query string or fragment", call. = FALSE)
	}
	# Ensure the HTTP VFS is registered in this process; try to lazily init if needed
	if (!sqliteHasHttpVFS()) {
		# Register via initExtension() using a throwaway in-memory connection
		tmp <- DBI::dbConnect(SQLite(), ":memory:")
		on.exit(try(DBI::dbDisconnect(tmp), silent = TRUE), add = TRUE)
		try(initExtension(tmp, "http"), silent = TRUE)
	}
	if (!sqliteHasHttpVFS()) {
		stop("HTTP VFS not available in this build", call. = FALSE)
	}
	uri <- paste0("file:", url)
	params <- c("vfs=http")
	if (isTRUE(immutable)) {
		params <- c(params, "immutable=1")
	}
	uri <- paste0(uri, "?", paste(params, collapse = "&"))
	DBI::dbConnect(
		SQLite(),
		uri,
		flags = SQLITE_RO,
		default.extensions = FALSE,
		...
	)
}
