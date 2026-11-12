# The warning about the values of an Arrow chunk that didn't fit the type of
# their column, raised once per chunk by the internal
# result_fetch_arrow_chunk(), see warn_coercion().
# The values themselves are checked in test-arrow-columns.R,
# test-arrow-text.R and test-arrow-dates.R.

test_that("one warning per chunk names the columns, values and rows", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, i, s, b, n)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, 1, 'a', x'01', NULL), (2, 2, 'b', x'02', NULL),",
    "(3, 'three', x'ff', 'c', 3), (4, 4.5, 4, x'04', 'd'), (5, 'v', 5, 5, NULL)"
  ))
  res <- local_result(con, "SELECT i, s, b, n FROM t ORDER BY id")
  expect_length(warnings_of(fetch_arrow_chunk(res, 2)), 0)
  expect_snapshot(chunk <- fetch_arrow_chunk(res))
  dbClearResult(res)

  # The warning carries what it reports
  res <- local_result(con, "SELECT i FROM t ORDER BY id")
  fetch_arrow_chunk(res, 2)
  warnings <- warnings_of(fetch_arrow_chunk(res))
  expect_length(warnings, 1)
  expect_s3_class(warnings[[1]], "RSQLite_warning_coercion")
  expect_equal(warnings[[1]]$coercions, list(list(
    column = "i",
    type = "int64",
    values = list(
      list(class = "text", reason = "converted", count = 2, rows = c(3, 5)),
      list(class = "real", reason = "converted", count = 1, rows = 4)
    )
  )))
})

test_that("reals in a fixed int64 column are converted, and NULL beyond it", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, x)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, 1), (2, 2.5), (3, -1e300), (4, '7 days'),",
    "(5, '99999999999999999999'), (6, x'3132'), (7, 7)"
  ))
  res <- local_result(con, "SELECT x FROM t ORDER BY id")
  fetch_arrow_chunk(res, 1)

  warnings <- warnings_of(chunk <- fetch_arrow_chunk(res))
  expect_coercions(warnings, paste(
    "Column `x` (int64): 1 real value converted (row 2);",
    "1 real value out of range, NULL instead (row 3);",
    "1 text value converted (row 4);",
    "1 text value out of range, NULL instead (row 5);",
    "1 blob value converted (row 6)"
  ))
  expect_equal(arrow_values(chunk)$x, c(2, NA, 7, NA, 12, 7))
})

test_that("text beyond int64 before a real widens the column is converted", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  res <- local_result(con, paste(
    "SELECT column1 AS x FROM (VALUES (1), ('99999999999999999999'),",
    "('2.5'), (x'3132'), (3.5))"
  ))

  # The column is double at the end of the chunk,
  # where the text beyond int64 has its reading as a real
  warnings <- warnings_of(chunk <- fetch_arrow_chunk(res))
  expect_coercions(warnings, paste(
    "Column `x` (double): 2 text values converted (rows 2 and 3);",
    "1 blob value converted (row 4)"
  ))
  expect_equal(arrow_values(chunk)$x, c(1, 1e20, 2.5, 12, 3.5))
})

test_that("values in a column of the null type are reported as dropped", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, x)")
  dbExecute(
    con,
    "INSERT INTO t VALUES (1, NULL), (2, 1), (3, 'a'), (4, NULL), (5, 2)"
  )
  res <- local_result(con, "SELECT x FROM t ORDER BY id")
  fetch_arrow_chunk(res, 1)

  expect_coercions(warnings_of(fetch_arrow_chunk(res)), paste(
    "Column `x` (null): 2 integer values dropped by the null type",
    "(rows 2 and 5); 1 text value dropped by the null type (row 3)"
  ))
})

test_that("text, blobs and numbers converted between them are reported", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, s, b, r)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, 'a', x'00', 1.5), (2, x'6162', 'text', '2.5'),",
    "(3, x'ff', 3, x'33'), (4, CAST(x'610062' AS TEXT), 4.5, 4), (5, 5, x'', 5)"
  ))
  res <- local_result(con, "SELECT s, b, r FROM t ORDER BY id")

  # Within the first chunk too; integers in a double column aren't reported
  expect_coercions(warnings_of(fetch_arrow_chunk(res)), c(
    paste(
      "Column `s` (utf8): 1 blob value converted (row 2);",
      "1 blob value not valid UTF-8 or with a NUL byte, NULL instead (row 3);",
      "1 text value not valid UTF-8 or with a NUL byte, NULL instead (row 4);",
      "1 integer value converted (row 5)"
    ),
    paste(
      "Column `b` (binary): 1 text value converted (row 2);",
      "1 integer value converted (row 3); 1 real value converted (row 4)"
    ),
    paste(
      "Column `r` (double): 1 text value converted (row 2);",
      "1 blob value converted (row 3)"
    )
  ))
})

test_that("dates and times that can't be parsed or are out of range are reported", {
  skip_if_not_installed("nanoarrow")
  con <- local_con(extended_types = TRUE)
  dbExecute(con, "CREATE TABLE t (id INTEGER, d DATE, tm TIME, ts TIMESTAMP)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, '2024-01-02', '12:00:00', '2024-01-02 12:00'),",
    "(2, 'tomorrow', x'00', 'noon'), (3, 3000000000, 86400, 1e300),",
    "(4, x'00', '25:00:00', x'00'), (5, 19000.5, 3600.5, 1.7e9)"
  ))
  res <- local_result(con, "SELECT d, tm, ts FROM t ORDER BY id")

  # Numbers within the range of the type are read as dbFetch() reads them
  expect_coercions(warnings_of(fetch_arrow_chunk(res)), c(
    paste(
      "Column `d` (date32): 1 text value not parsable, NULL instead (row 2);",
      "1 integer value out of range, NULL instead (row 3);",
      "1 blob value not parsable, NULL instead (row 4)"
    ),
    paste(
      "Column `tm` (time64[us]): 1 blob value not parsable, NULL instead",
      "(row 2); 1 integer value out of range, NULL instead (row 3);",
      "1 text value out of range, NULL instead (row 4)"
    ),
    paste(
      "Column `ts` (timestamp[us, UTC]): 1 text value not parsable,",
      "NULL instead (row 2); 1 real value out of range, NULL instead (row 3);",
      "1 blob value not parsable, NULL instead (row 4)"
    )
  ))
})

test_that("long lists of rows are shortened, large row numbers are in full", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  sql <- paste(
    "WITH RECURSIVE s(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM s",
    "WHERE i < 123456) SELECT CASE WHEN i BETWEEN 2 AND 31",
    "OR i IN (100000, 123456) THEN 'x' ELSE i END AS x FROM s"
  )
  res <- local_result(con, sql)

  expect_coercions(
    warnings_of(fetch_arrow_chunk(res, 31)),
    "Column `x` (int64): 30 text values converted (rows 2, 3, 4, 5, 6, ...)"
  )
  expect_coercions(
    warnings_of(fetch_arrow_chunk(res)),
    "Column `x` (int64): 2 text values converted (rows 100000 and 123456)"
  )

  # Row numbers beyond 2^31 need a 64-bit row count to reach,
  # their formatting is the same
  expect_equal(
    format_coercion_rows(6, 2^31 + 0:4),
    "rows 2147483648, 2147483649, 2147483650, 2147483651, 2147483652, ..."
  )
})

test_that("row numbers count across the result, as dbGetRowCount() does", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, x)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, 1), (2, 2), (3, 3), (4, 'a'), (5, 5), (6, 6),",
    "(7, 'c'), (8, 8), (9, 'd')"
  ))
  res <- local_result(con, "SELECT x FROM t ORDER BY id")

  expect_length(warnings_of(fetch_arrow_chunk(res, 3)), 0)
  expect_coercions(
    warnings_of(fetch_arrow_chunk(res, 2)),
    "Column `x` (int64): 1 text value converted (row 4)"
  )
  # A data frame fetch counts too, and keeps its own warning
  expect_warning(dbFetch(res, 2), "mixed type")
  expect_equal(dbGetRowCount(res), 7)
  expect_coercions(
    warnings_of(fetch_arrow_chunk(res)),
    "Column `x` (int64): 1 text value converted (row 9)"
  )
})

test_that("with options(warn = 2), the chunk is kept for the next fetch", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, x)")
  dbExecute(con, "INSERT INTO t VALUES (1, 1), (2, 'a'), (3, 3), (4, 4)")
  res <- local_result(con, "SELECT x FROM t ORDER BY id")
  withr::local_options(warn = 2)

  expect_error(
    fetch_arrow_chunk(res, 2),
    "(converted from warning) Values converted",
    fixed = TRUE
  )
  # The rows count once they are handed out, and the result goes on
  expect_true(dbIsValid(res))
  expect_false(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 0)
  expect_error(dbFetch(res), "Can't fetch a data frame before the Arrow chunk")

  # The next fetch hands out the chunk, whatever its `n`, without warning
  chunk <- fetch_arrow_chunk(res, 1)
  expect_equal(arrow_values(chunk)$x, c(1, 0))
  expect_equal(dbGetRowCount(res), 2)
  chunk <- fetch_arrow_chunk(res)
  expect_equal(arrow_values(chunk)$x, c(3, 4))
  expect_true(dbHasCompleted(res))
})

test_that("a handler that muffles the warning gets the chunk", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, x)")
  dbExecute(con, "INSERT INTO t VALUES (1, 1), (2, 'a')")
  res <- local_result(con, "SELECT x FROM t ORDER BY id")

  seen <- NULL
  chunk <- withCallingHandlers(
    fetch_arrow_chunk(res),
    RSQLite_warning_coercion = function(w) {
      # The chunk isn't handed out yet, and the result is busy
      seen <<- list(
        rows = dbGetRowCount(res),
        completed = dbHasCompleted(res),
        fetch = tryCatch(dbFetch(res), error = conditionMessage)
      )
      invokeRestart("muffleWarning")
    }
  )
  expect_equal(seen$rows, 0)
  expect_false(seen$completed)
  expect_match(seen$fetch, "Can't use a result while one of its fetches")
  expect_equal(arrow_values(chunk)$x, c(1, 0))
  expect_equal(dbGetRowCount(res), 2)
  expect_true(dbHasCompleted(res))
})

test_that("a handler that clears the result is refused, the chunk is kept", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, x)")
  dbExecute(con, "INSERT INTO t VALUES (1, 1), (2, 'a')")
  res <- local_result(con, "SELECT x FROM t ORDER BY id")

  expect_error(
    withCallingHandlers(
      fetch_arrow_chunk(res),
      RSQLite_warning_coercion = function(w) dbClearResult(res)
    ),
    "Can't clear a result while one of its fetches"
  )
  expect_true(dbIsValid(res))
  expect_length(warnings_of(chunk <- fetch_arrow_chunk(res)), 0)
  expect_equal(arrow_values(chunk)$x, c(1, 0))
  expect_true(dbHasCompleted(res))
})

test_that("a new execution drops a kept chunk", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, x)")
  dbExecute(con, "INSERT INTO t VALUES (1, 1), (2, 'a'), (3, 'c')")
  res <- local_result(con, "SELECT x FROM t WHERE id >= ? ORDER BY id")
  dbBind(res, list(1))
  expect_error(
    withCallingHandlers(
      fetch_arrow_chunk(res, 2),
      RSQLite_warning_coercion = function(w) stop("exited")
    ),
    "exited"
  )

  # The new execution decides its types anew
  dbBind(res, list(2))
  chunk <- fetch_arrow_chunk(res)
  expect_equal(arrow_formats(chunk), c(x = "u"))
  expect_equal(arrow_values(chunk)$x, c("a", "c"))
  expect_equal(dbGetRowCount(res), 2)
})

test_that("the values of a failed fetch aren't reported by the next one", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER PRIMARY KEY, x)")
  dbExecute(con, "INSERT INTO t VALUES (1, 1), (2, 'a'), (3, 3)")
  # Row 3 fails with an integer overflow after row 2 has been converted
  res <- local_result(con, paste(
    "SELECT CASE WHEN id = 3 THEN abs(-9223372036854775805 - id) ELSE x END",
    "AS x FROM t ORDER BY id"
  ))

  expect_error(fetch_arrow_chunk(res), "integer overflow")
  expect_length(warnings_of(chunk <- fetch_arrow_chunk(res)), 0)
  expect_equal(chunk$length, 0)
})

test_that("no warning when no value is converted", {
  skip_if_not_installed("nanoarrow")
  con <- local_con(extended_types = TRUE)
  dbExecute(con, "CREATE TABLE t (id INTEGER, i, r, n, e INTEGER, d DATE)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, 1, 1.5, NULL, NULL, '2024-01-02'),",
    "(2, NULL, 2, NULL, NULL, 19000), (3, 3.5, 3, NULL, NULL, 19000.5)"
  ))

  # Integers widen within a chunk, integers in a double column keep their
  # value, NULL fits any type, dates are text or numbers of days
  res <- local_result(con, "SELECT i, r, n, e, d FROM t ORDER BY id")
  expect_length(warnings_of(chunk <- fetch_arrow_chunk(res)), 0)
  expect_equal(
    arrow_formats(chunk),
    c(i = "g", r = "g", n = "n", e = "l", d = "tdD")
  )
  dbClearResult(res)

  # Also in later chunks, of the types fixed by the first
  res <- local_result(con, "SELECT r, n, e, d FROM t WHERE id > 1 ORDER BY id")
  for (n in c(1, 1, 1)) {
    expect_length(warnings_of(fetch_arrow_chunk(res, n)), 0)
  }
})
