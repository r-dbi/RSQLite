#' @rdname SQLite
#' @usage NULL
dbConnect_SQLiteConnection <- function(drv, ...) {
  # Match the arguments the way `dbConnect(SQLite(), ...)` would,
  # by name and by position.
  call <- match.call(dbConnect_SQLiteDriver, as.call(c(list(quote(f), NA), list(...))))
  args <- as.list(call)[-(1:2)]

  if (is.null(args$dbname) && drv@dbname %in% c("", ":memory:", "file::memory:")) {
    stop("Can't clone a temporary database", call. = FALSE)
  }

  defaults <- list(
    dbname = drv@dbname,
    vfs = drv@vfs, flags = drv@flags,
    loadable.extensions = drv@loadable.extensions,
    bigint = drv@bigint, extended_types = drv@extended_types
  )
  args <- utils::modifyList(defaults, args)

  do.call(dbConnect, c(list(SQLite()), args))
}
#' @rdname SQLite
#' @export
setMethod("dbConnect", "SQLiteConnection", dbConnect_SQLiteConnection)
