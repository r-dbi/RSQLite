# The internal read_arrow_stream(): a nanoarrow_array_stream over a result
# that fetches its chunks lazily, as result_fetch_arrow_chunk() builds them.

test_that("a stream reads the rows lazily, in chunks of at most `n` rows", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:7, b = letters[1:7]))
  res <- local_result(con, "SELECT a, b FROM t")
  stream <- read_arrow_stream(res, 3)

  lengths <- integer()
  rows <- integer()
  while (!is.null(chunk <- stream$get_next())) {
    lengths <- c(lengths, chunk$length)
    rows <- c(rows, dbGetRowCount(res))
  }
  expect_equal(lengths, c(3, 3, 1))
  expect_equal(rows, c(3, 6, 7))
  expect_true(dbHasCompleted(res))
  # The stream stays ended
  expect_null(stream$get_next())
})

test_that("a stream converts to the values that dbGetQuery() returns", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:5, b = c(1.5, NA, 3, 4, 5)))
  sql <- "SELECT a, b, CAST(a AS TEXT) AS c FROM t"
  expected <- dbGetQuery(con, sql)
  res <- local_result(con, sql)
  values <- nanoarrow::convert_array_stream(
    read_arrow_stream(res, 2),
    data.frame(a = double(), b = double(), c = character())
  )
  expect_equal(values, expected)
})

test_that("the schema comes from the first chunk, before any row is handed out", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  res <- local_result(con, "SELECT 1 AS x UNION ALL SELECT 2.5 UNION ALL SELECT 3")
  stream <- read_arrow_stream(res, 2)

  # The real in the first chunk makes the column double
  expect_equal(stream$get_schema()$children$x$format, "g")
  expect_equal(dbGetRowCount(res), 0)
  expect_false(dbHasCompleted(res))

  expect_equal(nanoarrow::convert_array(stream$get_next())$x, c(1, 2.5))
  # The integer in the second chunk fits the double column
  expect_equal(nanoarrow::convert_array(stream$get_next())$x, 3)
  expect_null(stream$get_next())
  expect_equal(stream$get_schema()$children$x$format, "g")
})

test_that("a stream of a result without rows has no chunk", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (a INTEGER, b TEXT)")
  res <- local_result(con, "SELECT a, b FROM t")
  stream <- read_arrow_stream(res)

  schema <- stream$get_schema()
  expect_equal(
    vapply(schema$children, function(child) child$format, character(1)),
    c(a = "l", b = "u")
  )
  expect_null(stream$get_next())
  expect_true(dbHasCompleted(res))
})

test_that("a stream warns once per chunk about converted values", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  res <- local_result(con, "SELECT 1 AS x UNION ALL SELECT 'a' UNION ALL SELECT 'b'")
  stream <- read_arrow_stream(res, 1)

  expect_length(warnings_of(stream$get_schema()), 0)
  expect_length(warnings_of(stream$get_next()), 0)
  expect_coercions(
    warnings_of(chunk <- stream$get_next()),
    "Column `x` (int64): 1 text value converted (row 2)"
  )
  expect_equal(chunk$length, 1)

  # A warning made an error leaves the stream by a jump, and keeps the chunk
  withr::with_options(
    list(warn = 2),
    expect_error(stream$get_next(), "converted from warning")
  )
  expect_length(warnings_of(chunk <- stream$get_next()), 0)
  expect_equal(nanoarrow::convert_array(chunk$children$x), 0)
  expect_null(stream$get_next())
})

test_that("a stream fails once its result is bound to new parameters", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  res <- local_result(con, "SELECT ? AS x UNION ALL SELECT 2")
  dbBind(res, list(1))
  stream <- read_arrow_stream(res, 1)
  expect_equal(stream$get_next()$length, 1)

  dbBind(res, list(3))
  expect_error(stream$get_next(), "after its result has been bound")
})

test_that("a stream keeps reading after R frees its result object", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  # Not registered with the connection, which would keep it
  sql <- "SELECT 1 AS x UNION ALL SELECT 2"
  res <- new(
    "SQLiteResult",
    sql = sql, ptr = result_create(con@ptr, sql), conn = con, bigint = con@bigint
  )
  stream <- read_arrow_stream(res, 1)
  rm(res)
  gc()
  values <- nanoarrow::convert_array_stream(stream)
  expect_equal(values$x, c(1, 2))
})

test_that("an error of SQLite fails the stream and completes the result", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbWriteTable(con, "t", data.frame(id = 1:5))
  # Row 4 fails with an integer overflow
  sql <- paste(
    "SELECT CASE WHEN id = 4 THEN abs(-9223372036854775804 - id) ELSE id END",
    "AS x FROM t"
  )

  # The failed step after a full chunk is kept for the next one
  res <- local_result(con, sql)
  stream <- read_arrow_stream(res, 3)
  expect_equal(stream$get_next()$length, 3)
  expect_false(dbHasCompleted(res))
  expect_error(stream$get_next(), "integer overflow")
  expect_true(dbHasCompleted(res))
  # The failure is final, not the end of a complete stream
  expect_error(stream$get_next(), "integer overflow")
  dbClearResult(res)

  # The failed step inside a chunk fails it
  res <- local_result(con, sql)
  stream <- read_arrow_stream(res, 5)
  expect_error(stream$get_next(), "integer overflow")
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 0)
  expect_error(stream$get_next(), "integer overflow")
  dbClearResult(res)

  # A failure while the schema is read is final too
  res <- local_result(con, sql)
  stream <- read_arrow_stream(res, 5)
  for (i in 1:3) {
    expect_error(nanoarrow::convert_array_stream(stream), "integer overflow")
  }
})

test_that("a stream can be released from a handler of its own warning", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  sql <- "SELECT 1 AS x UNION ALL SELECT 'a' UNION ALL SELECT 3"
  for (drop in c(FALSE, TRUE)) {
    # Not registered with the connection, so that R can free it
    res <- new(
      "SQLiteResult",
      sql = sql, ptr = result_create(con@ptr, sql), conn = con, bigint = con@bigint
    )
    stream <- read_arrow_stream(res, 3)
    if (drop) {
      rm(res)
      gc()
    }
    # The fetch goes on with the state and the result,
    # and nanoarrow fails when it asks the released stream for the schema
    expect_error(
      withCallingHandlers(
        stream$get_next(),
        RSQLite_warning_coercion = function(w) {
          stream$release()
          gc()
          invokeRestart("muffleWarning")
        }
      ),
      "already been released",
      info = drop
    )
    if (!drop) {
      expect_true(dbHasCompleted(res))
      dbClearResult(res)
    }
  }
})

test_that("a stream can be released from a handler while nanoarrow converts it", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  # The warning comes with the second chunk,
  # and nanoarrow asks the released stream for a third one
  res <- local_result(
    con,
    "SELECT 1 AS x UNION ALL SELECT 2 UNION ALL SELECT 'a' UNION ALL SELECT 4"
  )
  stream <- read_arrow_stream(res, 2)
  # From the stream, or "already been released" from a nanoarrow that checks
  expect_error(
    withCallingHandlers(
      nanoarrow::convert_array_stream(stream),
      RSQLite_warning_coercion = function(w) {
        stream$release()
        invokeRestart("muffleWarning")
      }
    ),
    "been released"
  )
})

test_that("a result is fetched either as data frames or as an Arrow stream", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()

  res <- local_result(con, "SELECT 1 AS x")
  read_arrow_stream(res)
  expect_error(dbFetch(res), class = "RSQLite_error_fetch_kind")
  expect_snapshot(dbFetch(res), error = TRUE)
  # Another stream is fine
  expect_equal(nanoarrow::convert_array_stream(read_arrow_stream(res))$x, 1)
  dbClearResult(res)

  res <- local_result(con, "SELECT 1 AS x")
  dbFetch(res, 0)
  expect_error(read_arrow_stream(res), class = "RSQLite_error_fetch_kind")
  expect_snapshot(read_arrow_stream(res), error = TRUE)
  expect_equal(dbFetch(res)$x, 1)
})

test_that("read_arrow_stream() checks `n`", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  res <- local_result(con, "SELECT 1 AS x")
  for (n in list(0, -2, 1.5, NA, "1", c(1, 2))) {
    expect_error(read_arrow_stream(res, n), "`n` must be", info = format(n))
  }
  expect_equal(nanoarrow::convert_array_stream(read_arrow_stream(res, -1))$x, 1)
})
