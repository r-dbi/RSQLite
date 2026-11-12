# Arrow arrays built from the date, time and timestamp columns of a result
# with `extended_types = TRUE`, through the internal result_fetch_arrow_chunk().
# Where the rules agree, each chunk is compared with what dbFetch() returns
# on the same connection, with the values converted to the same instants.

test_that("DATE, TIME and TIMESTAMP become date32, time64 and timestamp", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("hms")
  con <- local_con(extended_types = TRUE)
  dbExecute(con, paste(
    "CREATE TABLE t",
    "(id INTEGER, d DATE, tm TIME, ts TIMESTAMP, dt DateTime)"
  ))
  dbExecute(con, paste(
    "INSERT INTO t VALUES",
    "(1, '2024-01-02', '12:34:56', '2024-01-02 12:34:56', '2024-02-29 23:59'),",
    "(2, NULL, NULL, NULL, NULL),",
    "(3, '2024-Feb-29', '00:00:00', '2024-01-02 00:00:00', '2024-01-02 12')"
  ))

  sql <- "SELECT d, tm, ts, dt FROM t ORDER BY id"
  chunks <- expect_same_chunks(con, sql, c(1, 2))
  formats <- c(d = "tdD", tm = "ttu", ts = "tsu:UTC", dt = "tsu:UTC")
  expect_equal(arrow_formats(chunks[[1]]), formats)
  expect_equal(arrow_formats(chunks[[2]]), formats)
  values <- arrow_values(chunks[[2]])
  expect_identical(values$d, as.Date(c(NA, "2024-02-29")))
  expect_equal(values$tm, hms::hms(c(NA, 0)))
  expect_equal(values$ts, as.POSIXct(c(NA, "2024-01-02"), tz = "UTC"))
  expect_equal(chunks[[2]]$children$dt$null_count, 1L)
})

test_that("numbers are days or seconds since 1970, as dbFetch() reads them", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("hms")
  skip_if_not_installed("bit64")
  con <- local_con(extended_types = TRUE)
  dbExecute(con, "CREATE TABLE t (id INTEGER, d DATE, tm TIME, ts TIMESTAMP)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, 19724, 45296, 1704198896),",
    "(2, 19724.9, 45296.5, 1704198896.25), (3, -0.5, 0.1, -0.1),",
    # Julian days are a count of days or seconds since 1970 for both paths
    "(4, julianday('2024-01-02'), 86399.9999996, julianday('2024-01-02')),",
    "(5, NULL, 0.0000004, -0.0000016),",
    "(6, NULL, 0.0000025, 5000000000.000001),",
    "(7, NULL, 0.0000035, -5000000000.000001)"
  ))

  sql <- "SELECT d, tm, ts FROM t WHERE id < 5 ORDER BY id"
  chunks <- expect_same_chunks(con, sql, -1)
  # Days are truncated toward zero
  expect_identical(
    unclass(arrow_values(chunks[[1]])$d),
    c(19724, 19724, 0, 2460311)
  )
  # Seconds are rounded to the nearest microsecond, where dbFetch() keeps
  # what the double holds: halves to even, an odd count between 2^52 and 2^53
  # as it is, and a time before midnight to the last microsecond of the day
  chunk <- fetch_arrow_all(con, "SELECT tm, ts FROM t ORDER BY id")
  expect_identical(
    arrow_micros(chunk, "tm"),
    c("45296000000", "45296500000", "100000", "86399999999", "0", "2", "4")
  )
  expect_identical(arrow_micros(chunk, "ts"), c(
    "1704198896000000", "1704198896250000", "-100000", "2460311500000", "-2",
    "5000000000000001", "-5000000000000001"
  ))
})

test_that("fractional seconds keep their microseconds", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("hms")
  skip_if_not_installed("bit64")
  con <- local_con(extended_types = TRUE)
  dbExecute(con, "CREATE TABLE t (id INTEGER, tm TIME, ts TIMESTAMP)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, '00:00:00.5', '2024-01-02 00:00:00.5'),",
    "(2, '12:34:56.000001', '2024-01-02 12:34:56.000001'),",
    "(3, '12:34:56.1234567', '2024-01-02 12:34:56.123456789'),",
    "(4, 0.000001, 1704198896.000001)"
  ))

  chunks <- expect_same_chunks(con, "SELECT tm, ts FROM t ORDER BY id", -1)
  # Digits beyond microseconds are dropped from text, as dbFetch() drops them
  expect_identical(
    arrow_micros(chunks[[1]], "tm"),
    c("500000", "45296000001", "45296123456", "1")
  )
  expect_identical(arrow_micros(chunks[[1]], "ts"), c(
    "1704153600500000", "1704198896000001", "1704198896123456",
    "1704198896000001"
  ))
})

test_that("time zones and offsets in timestamps are read as by dbFetch()", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("bit64")
  withr::local_timezone("Pacific/Auckland")
  con <- local_con(extended_types = TRUE)
  dbExecute(con, "CREATE TABLE t (id INTEGER, ts TIMESTAMP)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, '2024-01-02 12:00:00'),",
    "(2, '2024-01-02 12:00:00Z'), (3, '2024-01-02 12:00:00+02:00'),",
    "(4, '2024-01-02 12:00:00 UTC'), (5, '2024-01-02T12:00:00'),",
    "(6, '2024-01-02 12:00:00-02:00')"
  ))

  # The time is UTC, whatever the time zone of the session
  sql <- "SELECT ts FROM t ORDER BY id"
  chunks <- expect_same_chunks(con, sql, -1, unparsable = TRUE)
  expect_equal(arrow_formats(chunks[[1]]), c(ts = "tsu:UTC"))
  # The parser of the data-frame path knows no time zone, offset or `T`,
  # and reads a negative offset as a fraction of a second
  expect_identical(
    arrow_micros(chunks[[1]], "ts"),
    c("1704196800000000", NA, NA, NA, NA, "1704196800020000")
  )
})

test_that("dates and timestamps before 1970 and after 2038", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("bit64")
  con <- local_con(extended_types = TRUE)
  dbExecute(con, "CREATE TABLE t (id INTEGER, d DATE, ts TIMESTAMP)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, '1400-01-01', '1400-01-01 00:00:00'),",
    "(2, '1969-12-31', '1969-12-31 23:59:59.999999'),",
    "(3, -25567, -2208988800.5), (4, '2038-01-20', '2038-01-19 03:14:08'),",
    "(5, 2932896, 4102444800), (6, '9999-12-31', '9999-12-31 23:59:59.999999')"
  ))
  sql <- "SELECT d, ts FROM t ORDER BY id"
  chunk <- fetch_arrow_all(con, sql)

  expect_identical(
    unclass(nanoarrow::convert_array(chunk$children$d)),
    c(-208188, -1, -25567, 24856, 2932896, 2932896)
  )
  # Exact beyond the 2^53 microseconds that a double holds
  micros <- arrow_micros(chunk, "ts")
  expect_identical(micros, c(
    "-17987443200000000", "-1", "-2208988800500000", "2147483648000000",
    "4102444800000000", "253402300799999999"
  ))
  expected <- dbGetQuery(con, sql)
  expect_equal(nanoarrow::convert_array(chunk$children$d), expected$d)
  expect_equal(as.numeric(micros) / 1e6, as.numeric(expected$ts))
})

test_that("values beyond the range of the Arrow type are NULL", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("hms")
  skip_if_not_installed("bit64")
  con <- local_con(extended_types = TRUE)
  dbExecute(con, "CREATE TABLE t (id INTEGER, d DATE, tm TIME, ts TIMESTAMP)")
  # 9e999 is an infinity in SQLite
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, 2147483647, 0, 9223372036854),",
    "(2, -2147483648, 86399.9999996, -9223372036854),",
    "(3, 2147483648, 86400, 9223372036855),",
    "(4, -2147483649, -1, -9223372036855),",
    "(5, 1e10, '24:00:00', 1e300), (6, 9e999, '-00:00:01', -9e999),",
    "(7, -9e999, '23:59:59.9999999', 1e19)"
  ))
  chunk <- fetch_arrow_all(
    con,
    "SELECT d, tm, ts FROM t ORDER BY id",
    converted = TRUE
  )

  expect_identical(
    unclass(nanoarrow::convert_array(chunk$children$d)),
    c(2147483647, -2147483648, NA, NA, NA, NA, NA)
  )
  # time64 holds a time of day
  expect_identical(
    arrow_micros(chunk, "tm"),
    c("0", "86399999999", NA, NA, NA, NA, "86399999999")
  )
  expect_identical(
    arrow_micros(chunk, "ts"),
    c("9223372036854000000", "-9223372036854000000", NA, NA, NA, NA, NA)
  )

  # dbFetch() keeps any duration, and wraps a count of days beyond 32 bits,
  # also of a real, which SQLite saturates at 64 bits first
  expected <- dbGetQuery(con, "SELECT d, tm FROM t ORDER BY id")
  expect_equal(
    as.numeric(expected$tm),
    c(0, 86399.9999996, 86400, -1, 86400, -1, 86399.999999)
  )
  expect_identical(
    unclass(expected$d)[3:7],
    c(-2147483648, 2147483647, 1410065408, -1, 0)
  )
})

test_that("blobs and text that can't be parsed are NULL, dbFetch() warns", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("hms")
  skip_if_not_installed("bit64")
  con <- local_con(extended_types = TRUE)
  dbExecute(con, "CREATE TABLE t (id INTEGER, d DATE, tm TIME, ts TIMESTAMP)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, x'07', x'07', x'07'),",
    "(2, 'not a date', 'x', 'not a timestamp'), (3, '', '', ''),",
    "(4, '2024-02-30', '12:xx', '2024-13-01 00:00:00'),",
    "(5, '1399-12-31', '1:2:3', '2024-01-02'),",
    "(6, '2024-01-02 12:00:00', '12:34', '2024-01-02 12')"
  ))

  sql <- "SELECT d, tm, ts FROM t ORDER BY id"
  chunks <- expect_same_chunks(con, sql, -1, unparsable = TRUE)
  # A date ignores what follows the day, a time takes hours and minutes,
  # a timestamp needs a time
  expect_identical(
    unclass(arrow_values(chunks[[1]])$d),
    c(NA, NA, NA, NA, NA, 19724)
  )
  expect_identical(
    arrow_micros(chunks[[1]], "tm"),
    c(NA, NA, NA, NA, "3723000000", "45240000000")
  )
  expect_identical(
    arrow_micros(chunks[[1]], "ts"),
    c(NA, NA, NA, NA, NA, "1704196800000000")
  )
})

test_that("text that runs out of memory fails its chunk at once", {
  skip_on_cran()
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("callr")
  skip_unless_callr_loads_tested_rsqlite()

  # As for the utf8, int64 and double columns of test-arrow-text.R:
  # the second row is the last of a chunk of one row,
  # and its 20 million characters, computed as it is read,
  # take 40 MB as UTF-16, and the UTF-8 text to parse more, beyond the limit
  for (type in c("DATE", "TIME", "TIMESTAMP")) {
    setup <- c(
      paste0(
        "CREATE TABLE t (n INTEGER, x ", type,
        " AS (iif(n = 1, '2024-01-02', printf('%.*c', 20000000, 'x'))))"
      ),
      "INSERT INTO t (n) VALUES (1), (2), (3)"
    )
    out <- fetch_arrow_chunk_out_of_memory(
      "SELECT x FROM t ORDER BY n",
      limit = 50000000,
      setup = setup,
      extended_types = TRUE
    )
    expect_match(out$error, "out of memory while reading a value", info = type)
    expect_true(out$completed)
    expect_equal(out$rows, 1L)
  }
})

test_that("columns of only NULL take their declared type", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("hms")
  con <- local_con(extended_types = TRUE)
  dbExecute(con, "CREATE TABLE t (id INTEGER, d DATE, tm TIME, ts TIMESTAMP)")
  formats <- c(d = "tdD", tm = "ttu", ts = "tsu:UTC")

  # Also in a result of no rows
  chunk <- fetch_arrow_all(con, "SELECT d, tm, ts FROM t")
  expect_equal(arrow_formats(chunk), formats)
  expect_equal(chunk$length, 0)

  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, NULL, NULL, NULL), (2, NULL, NULL, NULL),",
    "(3, '2024-01-02', '12:00:00', 0)"
  ))
  sql <- "SELECT d, tm, ts FROM t ORDER BY id"
  chunks <- expect_same_chunks(con, sql, c(2, 1))
  expect_equal(arrow_formats(chunks[[1]]), formats)
  expect_equal(chunks[[1]]$children$tm$null_count, 2L)
  expect_equal(arrow_formats(chunks[[2]]), formats)
})

test_that("text, numbers, blobs and NULL mix in a column, in any chunks", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("hms")
  con <- local_con(extended_types = TRUE)
  dbExecute(con, "CREATE TABLE t (id INTEGER, d DATE, tm TIME, ts TIMESTAMP)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, NULL, 3600, x'00'),",
    "(2, 19724, NULL, '2024-01-02 12:34:56'),",
    "(3, '2024-01-03', '01:00:00.25', 1704198896.5),",
    "(4, x'01', 7200.75, NULL),",
    "(5, 19726.7, 'x', 1704198896), (6, 'x', x'02', 'x'),",
    "(7, '2024-01-06', '23:59:59', -1)"
  ))

  sql <- "SELECT d, tm, ts FROM t ORDER BY id"
  for (ns in list(-1, rep(1, 8), c(2, 3, 4))) {
    expect_same_chunks(con, sql, ns, unparsable = TRUE)
  }

  # A new execution takes the declared types again
  res <- local_result(con, "SELECT d FROM t WHERE id = ?")
  for (id in c(1, 3)) {
    dbBind(res, list(id))
    expect_equal(arrow_formats(fetch_arrow_chunk(res)), c(d = "tdD"))
  }
})

test_that("declared types match as for dbFetch(), expressions follow values", {
  skip_if_not_installed("nanoarrow")
  con <- local_con(extended_types = TRUE)
  dbExecute(con, "CREATE TABLE t (a date, b TimeStamp, c DATETIME(6), d DATE_)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES",
    "('2024-01-02', '2024-01-02 00:00:00', '2024-01-02 00:00:00', '2024-01-02')"
  ))

  sql <- "SELECT a, b, c, d, date(a) AS e, a AS f FROM t"
  chunks <- expect_same_chunks(con, sql, -1)
  expect_equal(
    arrow_formats(chunks[[1]]),
    c(a = "tdD", b = "tsu:UTC", c = "u", d = "u", e = "u", f = "tdD")
  )
})

test_that("text is parsed as UTF-8 in a UTF-16 database", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("hms")
  skip_if_not_installed("bit64")
  con <- local_con(extended_types = TRUE)
  dbExecute(con, "PRAGMA encoding = 'UTF-16'")
  dbExecute(con, "CREATE TABLE t (d DATE, tm TIME, ts TIMESTAMP)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES",
    "('2024-01-02', '12:34:56.5', '2024-01-02 12:34:56.5')"
  ))

  chunks <- expect_same_chunks(con, "SELECT d, tm, ts FROM t", -1)
  expect_identical(arrow_micros(chunks[[1]], "ts"), "1704198896500000")
})

test_that("without extended_types, these columns follow their values", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, d DATE, tm TIME, ts TIMESTAMP)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, '2024-01-02', 3600, NULL),",
    "(2, NULL, 7200, NULL)"
  ))

  sql <- "SELECT d, tm, ts FROM t ORDER BY id"
  chunks <- expect_same_chunks(con, sql, -1)
  # A column of only NULL takes the double of NUMERIC affinity
  expect_equal(arrow_formats(chunks[[1]]), c(d = "u", tm = "l", ts = "g"))
})
