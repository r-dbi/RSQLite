# Package hooks

.onLoad <- function(libname, pkgname) {
  # Memoize one-time warnings early
  if (!inherits(warning_once, "memoised")) {
    warning_once <<- memoise::memoise(warning_once)
  }

  # Eagerly register HTTP VFS only if compiled in (compile-time gated)
  if (exists("sqlite_httpvfs_compiled") && isTRUE(sqlite_httpvfs_compiled())) {
    # Keep side effects minimal and ignore all errors; lazy path remains available
    try(
      {
        con <- DBI::dbConnect(SQLite(), ":memory:")
        on.exit(try(DBI::dbDisconnect(con), silent = TRUE), add = TRUE)
        initExtension(con, "http")
      },
      silent = TRUE
    )
  }
}

.onUnload <- function(libpath) {
  gc() # Force garbage collection of connections
  library.dynam.unload("RSQLite", libpath)
}
