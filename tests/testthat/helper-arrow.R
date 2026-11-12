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
# or all of a chunk kept when its warning exited,
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

# Writes a table `t` with a row for each of `sizes`, numbered by `i`:
# `s` holds text of that many bytes and `b` a blob of that many bytes,
# both NULL for NA
write_sized_table <- function(con, sizes) {
  blobs <- lapply(sizes, function(size) if (!is.na(size)) as.raw(rep(1, size)))
  dbWriteTable(con, "t", data.frame(
    i = seq_along(sizes),
    s = strrep("x", sizes),
    b = blob::as_blob(blobs)
  ))
}

# A result of `sql` whose Arrow chunks hold at most `max_bytes` bytes of text
# or blobs per column instead of 2^31 - 1, so that the tests of the limit
# need little memory; cleared as by local_result()
local_limited_result <- function(con, sql, max_bytes, envir = parent.frame()) {
  res <- local_result(con, sql, envir = envir)
  result_set_arrow_max_bytes(res@ptr, max_bytes)
  res
}

# The chunks of at most `n` rows of `res` until it completes, each checked
# with expect_valid_chunk(), and expecting dbGetRowCount() to count their rows.
# With `converted = TRUE`, the warnings about converted values are muffled.
fetch_arrow_chunks <- function(res, n = -1L, converted = FALSE) {
  chunks <- list()
  rows <- dbGetRowCount(res)
  while (!dbHasCompleted(res)) {
    chunk <- withCallingHandlers(
      fetch_arrow_chunk(res, n),
      RSQLite_warning_coercion = function(w) {
        if (converted) {
          invokeRestart("muffleWarning")
        }
      }
    )
    expect_valid_chunk(chunk)
    # An empty chunk before the end would never end the loop
    expect_gt(chunk$length, 0)
    if (chunk$length == 0) {
      break
    }
    rows <- rows + chunk$length
    expect_equal(dbGetRowCount(res), rows)
    chunks[[length(chunks) + 1]] <- chunk
  }
  chunks
}

# The numbers of rows of `chunks`
chunk_lengths <- function(chunks) {
  vapply(chunks, function(chunk) chunk$length, numeric(1))
}

# A nanoarrow array of the integer type `schema`, int8 to uint32,
# with `values` and nulls for NA, which nanoarrow doesn't convert without arrow
arrow_int_array <- function(values, schema) {
  size <- c(c = 1, C = 1, s = 2, S = 2, i = 4, I = 4)[[schema$format]]
  valid <- !is.na(values)
  values[!valid] <- 0L
  nanoarrow::nanoarrow_array_modify(nanoarrow::nanoarrow_array_init(schema), list(
    length = length(values),
    null_count = sum(!valid),
    buffers = list(
      nanoarrow::as_nanoarrow_array(valid, schema = nanoarrow::na_bool())$buffers[[2]],
      nanoarrow::as_nanoarrow_buffer(
        writeBin(as.integer(values), raw(), size = size, endian = "little")
      )
    )
  ))
}

# A stream of one struct array with the arrays `...` as its columns,
# unnamed unless named
arrow_params <- function(...) {
  arrays <- list(...)
  if (is.null(names(arrays))) {
    names(arrays) <- rep("", length(arrays))
  }
  schema <- nanoarrow::na_struct(lapply(arrays, nanoarrow::infer_nanoarrow_schema))
  array <- nanoarrow::nanoarrow_array_modify(
    nanoarrow::nanoarrow_array_init(schema),
    list(length = arrays[[1]]$length, children = arrays)
  )
  nanoarrow::basic_array_stream(list(array))
}

# The values that `stream` binds, as text, and their storage classes,
# one row per row of the stream
bound_values <- function(con, stream) {
  res <- dbSendQuery(con, "SELECT CAST(?1 AS TEXT) AS x, typeof(?1) AS type")
  on.exit(dbClearResult(res))
  bind_arrow_stream(res, stream)
  dbFetch(res)
}
