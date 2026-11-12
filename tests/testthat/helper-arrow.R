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
# as a nanoarrow_array of a struct type.
# With `converted = TRUE`, expects the warning about values converted to the
# type of their column, whose text test-arrow-coercion.R checks
fetch_arrow_chunk <- function(res, n = -1L, converted = FALSE) {
  if (!converted) {
    return(result_fetch_arrow_chunk(res@ptr, n))
  }
  expect_warning(
    chunk <- result_fetch_arrow_chunk(res@ptr, n),
    class = "RSQLite_warning_coercion"
  )
  chunk
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
# and with `unparsable = TRUE` of dates and times it can't convert;
# with either, the Arrow chunks may warn of values converted to the type of
# their column.
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
    chunk <- withCallingHandlers(
      fetch_arrow_chunk(res, n),
      RSQLite_warning_coercion = function(w) {
        if (mixed || unparsable) {
          invokeRestart("muffleWarning")
        }
      }
    )
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
# with the result cleared; `converted` as for fetch_arrow_chunk()
fetch_arrow_all <- function(con, sql, converted = FALSE) {
  res <- dbSendQuery(con, sql)
  on.exit(dbClearResult(res))
  chunk <- fetch_arrow_chunk(res, converted = converted)
  expect_valid_chunk(chunk)
  chunk
}

# The warnings that `expr` raises, muffled
warnings_of <- function(expr) {
  warnings <- list()
  withCallingHandlers(
    expr,
    warning = function(w) {
      warnings[[length(warnings) + 1]] <<- w
      invokeRestart("muffleWarning")
    }
  )
  warnings
}

# Expects `warnings` to be one warning about values converted to the type of
# their column, with a line for each column as in `lines`
expect_coercions <- function(warnings, lines) {
  expect_length(warnings, 1)
  expect_s3_class(warnings[[1]], "RSQLite_warning_coercion")
  expect_equal(
    vapply(warnings[[1]]$coercions, format_coercion_column, character(1)),
    lines
  )
}
