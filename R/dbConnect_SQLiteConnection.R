#' @rdname SQLite
#' @usage NULL
dbConnect_SQLiteConnection <- function(drv, dbname = drv@dbname, ..., loadable.extensions = drv@loadable.extensions,
                                       default.extensions = loadable.extensions, cache_size = NULL,
                                       synchronous = "off", flags = drv@flags, vfs = drv@vfs,
                                       bigint = drv@bigint,
                                       extended_types = drv@extended_types,
                                       check_utf8 = drv@check_utf8) {
  # The formals mirror those of `dbConnect_SQLiteDriver()`,
  # with the connection's own settings as defaults;
  # a test checks that the two stay in step.
  if (missing(dbname) && drv@dbname %in% c("", ":memory:", "file::memory:")) {
    stop("Can't clone a temporary database", call. = FALSE)
  }

  dbConnect_SQLiteDriver(
    SQLite(),
    dbname = dbname,
    ...,
    loadable.extensions = loadable.extensions,
    default.extensions = default.extensions,
    cache_size = cache_size,
    synchronous = synchronous,
    flags = flags,
    vfs = vfs,
    bigint = bigint,
    extended_types = extended_types,
    check_utf8 = check_utf8
  )
}
#' @rdname SQLite
#' @export
setMethod("dbConnect", "SQLiteConnection", dbConnect_SQLiteConnection)
