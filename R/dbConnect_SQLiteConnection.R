slot_or_default <- function(object, name, default) {
  if (methods::.hasSlot(object, name)) methods::slot(object, name) else default
}

#' @rdname SQLite
#' @usage NULL
dbConnect_SQLiteConnection <- function(drv, dbname = drv@dbname, ..., loadable.extensions = drv@loadable.extensions,
                                       default.extensions = loadable.extensions, cache_size = NULL,
                                       synchronous = "off", flags = drv@flags, vfs = drv@vfs,
                                       bigint = slot_or_default(drv, "bigint", "integer64"),
                                       extended_types = slot_or_default(drv, "extended_types", FALSE),
                                       check_utf8 = slot_or_default(drv, "check_utf8", FALSE)) {
  # The formals mirror those of `dbConnect_SQLiteDriver()`,
  # with the connection's own settings as defaults;
  # a test checks that the two stay in step.
  # A connection saved by an older RSQLite may lack the newer slots:
  # those fall back to the driver's defaults.
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
