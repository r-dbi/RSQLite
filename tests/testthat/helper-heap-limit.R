# Caps SQLite's heap at what it uses now plus `headroom` bytes,
# and restores the earlier limits when the calling test finishes.
# The heap limits apply to the whole process,
# and PRAGMA hard_heap_limit cannot lift them, so this uses the C API.
local_sqlite_heap_limit <- function(headroom, .env = parent.frame()) {
  prior <- sqlite_heap_limits(sqlite_memory_used() + headroom, -1)
  withr::defer(
    sqlite_heap_limits(prior[["hard"]], prior[["soft"]]),
    envir = .env
  )
  invisible(prior)
}

# A UTF-16 database with a text value of 4 million characters in `t.s`:
# stepping to it needs about 9 MB of heap,
# and converting it to UTF-8 for R needs about 24 MB.
local_utf16_large_text_con <- function(..., .env = parent.frame()) {
  con <- dbConnect(SQLite(), ":memory:", ...)
  withr::defer(dbDisconnect(con), envir = .env)
  dbExecute(con, "PRAGMA encoding = 'UTF-16le'")
  dbExecute(con, "CREATE TABLE t (id INTEGER, s TEXT, d DATE)")
  dbExecute(
    con,
    "INSERT INTO t VALUES (1, 'a', '2026-01-02'), (2, ?1, ?1)",
    params = list(strrep("x", 4e6))
  )
  con
}
