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

# The data frames of a sequence of fetches, and the number of warnings of each
# fetch; `chunk_size` sets the rows per Arrow array of a fetch through Arrow.
# `info` asks dbColumnInfo() before each fetch, which decides the types of the
# next fetch on the default path, and pairs its answer with each data frame.
# Only the warnings of the fetches are counted.
fetch_sequence <- function(con, sql, ns, chunk_size = NULL, info = FALSE) {
  rs <- dbSendQuery(con, sql)
  on.exit(dbClearResult(rs), add = TRUE, after = FALSE)
  warnings <- integer(length(ns))
  data <- lapply(seq_along(ns), function(i) {
    column_info <- if (info) suppressWarnings(dbColumnInfo(rs))
    df <- withCallingHandlers(
      if (is.null(chunk_size)) {
        dbFetch(rs, ns[[i]])
      } else {
        arrow_fetch_df(rs, ns[[i]], chunk_size = chunk_size)
      },
      warning = function(w) {
        warnings[[i]] <<- warnings[[i]] + 1L
        invokeRestart("muffleWarning")
      }
    )
    if (info) list(info = column_info, df = df) else df
  })
  list(data = data, warnings = warnings)
}

# Compares the fetch_sequence() of the Arrow path with that of the default path.
# The default path warns once per column with mixed types,
# the Arrow path once per fetch.
# A fetch of no rows warns on the default path when the next row holds a value
# of another storage class, never through Arrow: it returns no value.
expect_same_fetches <- function(actual, expected, ns, info) {
  expect_identical(actual$data, expected$data, info = info)
  warned <- pmin(expected$warnings, 1L)
  warned[ns == 0] <- 0L
  expect_identical(actual$warnings, warned, info = info)
}

# The coercion warnings that `expr` raises, muffled
coercion_warnings <- function(expr) {
  out <- list()
  withCallingHandlers(
    expr,
    RSQLite_warning_coercion = function(w) {
      out[[length(out) + 1]] <<- w
      invokeRestart("muffleWarning")
    }
  )
  out
}
