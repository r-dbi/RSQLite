# Helpers for the tests of the Arrow arrays of a result, defined here rather
# than in the test files so that each test_that() block also runs on its own
# after load_all()

# An in-memory connection, disconnected when `envir` exits
local_con <- function(..., envir = parent.frame()) {
  con <- dbConnect(SQLite(), ":memory:", ...)
  withr::defer(dbDisconnect(con), envir = envir)
  con
}

# A result of `sql`, cleared when `envir` exits unless it was cleared before
local_result <- function(con, sql, envir = parent.frame()) {
  res <- dbSendQuery(con, sql)
  withr::defer(if (dbIsValid(res)) dbClearResult(res), envir = envir)
  res
}

# The next chunk of at most `n` rows of `res`, all of them for -1,
# as a nanoarrow_array of a struct type
fetch_arrow_chunk <- function(res, n = -1L) {
  result_fetch_arrow_chunk(res@ptr, n)
}

# The Arrow format of each column of a chunk, by column name
arrow_formats <- function(chunk) {
  schema <- nanoarrow::infer_nanoarrow_schema(chunk)
  vapply(schema$children, function(child) child$format, character(1))
}

# The values of a chunk as a data frame:
# int64 columns as `int64`, double by default, and the null type as logical
arrow_values <- function(chunk, int64 = double()) {
  ptype <- lapply(arrow_formats(chunk), function(format) {
    switch(format, l = int64, g = double(), n = logical())
  })
  ptype <- structure(ptype, class = "data.frame", row.names = integer())
  nanoarrow::convert_array(chunk, ptype)
}

# Fetches `sql` in chunks of `ns` rows through Arrow, and again with dbFetch(),
# and expects the same values, dbHasCompleted() and dbGetRowCount() after
# each chunk; `int64` as for arrow_values().
# Returns the Arrow chunks.
expect_same_chunks <- function(con, sql, ns, int64 = double()) {
  res <- dbSendQuery(con, sql)
  expected <- lapply(ns, function(n) {
    list(
      values = dbFetch(res, n),
      completed = dbHasCompleted(res),
      rows = dbGetRowCount(res)
    )
  })
  dbClearResult(res)

  res <- dbSendQuery(con, sql)
  on.exit(dbClearResult(res))
  chunks <- list()
  actual <- lapply(ns, function(n) {
    chunk <- fetch_arrow_chunk(res, n)
    chunks[[length(chunks) + 1]] <<- chunk
    list(
      values = arrow_values(chunk, int64),
      completed = dbHasCompleted(res),
      rows = dbGetRowCount(res)
    )
  })
  expect_equal(actual, expected)
  invisible(chunks)
}
