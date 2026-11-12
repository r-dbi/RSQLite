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
# int64 columns as `int64`, double by default, the null type as logical,
# utf8 as character, binary as blob, date32 as Date, time64 as hms
# and timestamp as POSIXct in UTC, as dbFetch() returns them
arrow_values <- function(chunk, int64 = double()) {
  ptype <- lapply(arrow_formats(chunk), function(format) {
    switch(
      format,
      l = int64,
      g = double(),
      n = logical(),
      u = character(),
      z = blob::blob(),
      tdD = structure(double(), class = "Date"),
      ttu = hms::hms(),
      "tsu:UTC" = .POSIXct(double(), tz = "UTC")
    )
  })
  ptype <- structure(ptype, class = "data.frame", row.names = integer())
  nanoarrow::convert_array(chunk, ptype)
}

# Expects `chunk` to pass nanoarrow's full validation, which reading it back
# from the Arrow IPC format runs, and its utf8 values to be valid UTF-8,
# which Arrow's full validation adds.
# Converting a utf8 value with a NUL byte to R would fail.
expect_valid_chunk <- function(chunk) {
  path <- withr::local_tempfile()
  nanoarrow::write_nanoarrow(chunk, path)
  stream <- nanoarrow::read_nanoarrow(path)
  expect_equal(stream$get_next()$length, chunk$length)
  stream$release()

  for (child in chunk$children[arrow_formats(chunk) == "u"]) {
    expect_true(all(validUTF8(nanoarrow::convert_array(child, character()))))
  }
}

# Fetches `sql` in chunks of `ns` rows through Arrow, and again with dbFetch(),
# and expects the same values, dbHasCompleted() and dbGetRowCount() after
# each chunk, and valid chunks; `int64` as for arrow_values().
# With `mixed = TRUE`, dbFetch() may warn of a column of mixed types,
# and with `unparsable = TRUE` of dates and times it can't convert.
# Returns the Arrow chunks.
expect_same_chunks <- function(con, sql, ns, int64 = double(), mixed = FALSE,
                               unparsable = FALSE) {
  res <- dbSendQuery(con, sql)
  expected <- lapply(ns, function(n) {
    values <- withCallingHandlers(
      dbFetch(res, n),
      warning = function(w) {
        message <- conditionMessage(w)
        if ((mixed && grepl("mixed type", message)) ||
          (unparsable && grepl("NA is returned", message))) {
          invokeRestart("muffleWarning")
        }
      }
    )
    list(
      values = values,
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
    expect_valid_chunk(chunk)
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

# The values of a time64[us] or timestamp[us] column of `chunk` as strings
# of whole microseconds, NA for NULL: exact also beyond the 2^53 that a
# conversion to seconds would round
arrow_micros <- function(chunk, name) {
  micros <- nanoarrow::convert_array(chunk$children[[name]], bit64::integer64())
  as.character(micros)
}

# All rows of `sql` as one Arrow chunk, checked with expect_valid_chunk(),
# with the result cleared
fetch_arrow_all <- function(con, sql) {
  res <- dbSendQuery(con, sql)
  on.exit(dbClearResult(res))
  chunk <- fetch_arrow_chunk(res)
  expect_valid_chunk(chunk)
  chunk
}

# Fetches a first chunk of one row of `sql` in a UTF-16 database
# in a new R session, limits SQLite's heap to `limit` bytes,
# and fetches a second chunk of one row.
# SQLite can't lift the limit again, hence the session of its own.
# The statements of `setup` run before `sql`,
# on a connection with `extended_types` as given.
# Returns the error of the second fetch or the value of its column `x`,
# and the state of the result after it.
fetch_arrow_chunk_out_of_memory <- function(sql, limit, setup = character(),
                                            extended_types = FALSE) {
  callr::r(
    function(sql, limit, setup, extended_types) {
      library(RSQLite)
      con <- dbConnect(SQLite(), ":memory:", extended_types = extended_types)
      other <- dbConnect(SQLite(), ":memory:")
      dbExecute(con, "PRAGMA encoding = 'UTF-16'")
      for (statement in setup) {
        dbExecute(con, statement)
      }
      res <- dbSendQuery(con, sql)
      RSQLite:::result_fetch_arrow_chunk(res@ptr, 1L)
      dbExecute(other, paste("PRAGMA hard_heap_limit =", limit))
      value <- NULL
      error <- tryCatch(
        {
          chunk <- RSQLite:::result_fetch_arrow_chunk(res@ptr, 1L)
          value <- nanoarrow::convert_array(chunk)$x
          NA_character_
        },
        error = conditionMessage
      )
      list(
        error = error,
        value = value,
        completed = dbHasCompleted(res),
        rows = dbGetRowCount(res)
      )
    },
    list(sql, format(limit, scientific = FALSE), setup, extended_types)
  )
}
