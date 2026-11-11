# Helpers for the Arrow tests, defined here rather than in the test files
# so that each test_that() block also runs on its own after load_all()

# An in-memory connection, disconnected when `envir` exits
local_con <- function(..., envir = parent.frame()) {
  con <- dbConnect(SQLite(), ":memory:", ...)
  withr::defer(dbDisconnect(con), envir = envir)
  con
}

# An in-memory connection with `arrow = TRUE`, disconnected when `envir` exits
local_arrow_con <- function(..., envir = parent.frame()) {
  con <- dbConnect(SQLite(), ":memory:", arrow = TRUE, ...)
  withr::defer(dbDisconnect(con), envir = envir)
  con
}

# The Arrow format of each column of `x`, by column name
schema_formats <- function(x) {
  schema <- nanoarrow::infer_nanoarrow_schema(x)
  vapply(schema$children, function(child) child$format, character(1))
}

# The lengths of the arrays a stream yields, which are released on the way
chunk_lengths <- function(stream) {
  lengths <- numeric()
  repeat {
    array <- stream$get_next()
    if (is.null(array)) {
      break
    }
    lengths <- c(lengths, array$length)
    nanoarrow::nanoarrow_pointer_release(array)
  }
  lengths
}

# Lowers, for the result `rs` alone, the bytes of a string or binary column
# after which, or beyond which, a chunk ends, from 1 GiB and 2^31 - 1
set_bytes_limits <- function(rs, cut_bytes = 100, max_bytes = 150) {
  if (methods::is(rs, "SQLiteResultArrow")) {
    rs <- rs@result
  }
  result_set_bytes_limits(rs@ptr, cut_bytes, max_bytes)
}

# A lazy stream over `sql` with the byte limits lowered to 100 and 150,
# `...` goes to dbSendQueryArrow(); the stream reads on after its result has
# been cleared
fetch_with_bytes_limits <- function(con, sql, ...) {
  rs <- dbSendQueryArrow(con, sql, ...)
  on.exit(dbClearResult(rs))
  set_bytes_limits(rs)
  dbFetchArrow(rs)
}

# The data frames of a sequence of fetches; `chunk_size` sets the rows per
# Arrow array of a fetch through Arrow, `info` asks dbColumnInfo() before each
# fetch, which decides the types of the next fetch on the default path
fetch_sequence <- function(con, sql, ns, chunk_size = NULL, info = FALSE) {
  rs <- dbSendQuery(con, sql)
  on.exit(dbClearResult(rs), add = TRUE, after = FALSE)
  lapply(ns, function(n) {
    suppressWarnings(list(
      info = if (info) dbColumnInfo(rs),
      df = if (is.null(chunk_size)) {
        dbFetch(rs, n)
      } else {
        arrow_fetch_df(rs, n, chunk_size = chunk_size)
      }
    ))
  })
}
