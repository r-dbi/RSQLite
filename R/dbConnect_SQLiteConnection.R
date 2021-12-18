#' @rdname SQLite
#' @usage NULL
dbConnect_SQLiteConnection <- function(drv, ...) {
  if (drv@dbname %in% c("", ":memory:", "file::memory:")) {
    stop("Can't clone a temporary database", call. = FALSE)
  }

  dbConnect(SQLite(), drv@dbname,
    vfs = drv@vfs, flags = drv@flags,
    loadable.extensions = drv@loadable.extensions
  )
}
#' @rdname SQLite
#' @export
setMethod("dbConnect", "SQLiteConnection", dbConnect_SQLiteConnection)
