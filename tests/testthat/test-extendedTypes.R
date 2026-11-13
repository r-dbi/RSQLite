test_that("Can read dates", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "drop table if exists t1")
  dbExecute(con, "create table t1(dt DATE)")
  dbExecute(con, "insert into t1 values (1), (18612.2), ('2020-01-10') , ('not a date'), (?)", params = as.Date("2021-12-11"))

  expect_warning(resdf <- dbGetQuery(con, "SELECT * from t1"), "Unknown string format, NA is returned.")
  expect_equal(resdf[[1]], as.Date(c("1970-01-02", "2020-12-16", "2020-01-10", NA, "2021-12-11")))
})

test_that("Can read datetime", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "drop table if exists t1")
  dbExecute(con, "create table t1(dt DATETIME)")
  dbExecute(con, "insert into t1 values (1), (1608110307.2), ('2020-01-10 12:13:14'), ('not a date'), (?)",
    params = as.POSIXct("2021-11-12 13:12:11", tz = "UTC")
  )

  expect_warning(resdf <- dbGetQuery(con, "SELECT * from t1"), "Unknown string format, NA is returned.")
  expect_equal(resdf[[1]], as.POSIXct(c("1970-01-01 00:00:01", "2020-12-16 09:18:27.2", "2020-01-10 12:13:14", NA, "2021-11-12 13:12:11"), tz = "UTC"))
})



test_that("Can read time", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "drop table if exists t1")
  dbExecute(con, "create table t1(dt TIME)")
  dbExecute(con, "insert into t1 values (1), (-90000.2), ('25:12:13.123') , ('not a time'), (?)",
    params = structure(123, units = "secs", class = c("hms", "difftime"))
  )

  expect_warning(resdf <- dbGetQuery(con, "SELECT * from t1"), "Unknown string format, NA is returned.")
  expected_times <- structure(c(1, -90000.2, 90733.123, NA, 123), units = "secs", class = c("hms", "difftime"))
  expect_equal(resdf[[1]], expected_times)
})


test_that("Columninfo dates", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "drop table if exists t1")
  dbExecute(con, "create table t1(dt DATE)")

  stmt <- dbSendQuery(con, "select * from t1")
  on.exit(dbClearResult(stmt), add = TRUE, after = FALSE)

  col_info <- dbColumnInfo(stmt)
  expect_equal(col_info$type, "Date")
})

test_that("Columninfo datetime", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "drop table if exists t1")
  dbExecute(con, "create table t1(dt DATETIME)")

  stmt <- dbSendQuery(con, "select * from t1")
  on.exit(dbClearResult(stmt), add = TRUE, after = FALSE)

  col_info <- dbColumnInfo(stmt)
  expect_equal(col_info$type, "POSIXct")
})



test_that("Columninfo time", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "drop table if exists t1")
  dbExecute(con, "create table t1(dt TIME)")

  stmt <- dbSendQuery(con, "select * from t1")
  on.exit(dbClearResult(stmt), add = TRUE, after = FALSE)

  col_info <- dbColumnInfo(stmt)
  expect_equal(col_info$type, "hms")
})



test_that("Blob as dates", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "drop table if exists t1")
  dbExecute(con, "create table t1(dt DATE)")
  dbExecute(con, "insert into t1 values (?)", params = list(blob::as_blob(as.raw(7))))

  expect_warning(resdf <- dbGetQuery(con, "SELECT * from t1"), "Cannot convert blob, NA is returned.")
  expect_equal(resdf[[1]], as.Date(NA))
})

test_that("Blob as datetime", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "drop table if exists t1")
  dbExecute(con, "create table t1(dt DATETIME)")
  dbExecute(con, "insert into t1 values (?)", params = list(blob::as_blob(as.raw(7))))

  expect_warning(resdf <- dbGetQuery(con, "SELECT * from t1"), "Cannot convert blob, NA is returned.")
  expect_equal(resdf[[1]], as.POSIXct(NA_real_, origin = "1970-01-01", tz = "UTC"))
})


test_that("Blob as time", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "drop table if exists t1")
  dbExecute(con, "create table t1(dt TIME)")
  dbExecute(con, "insert into t1 values (?)", params = list(blob::as_blob(as.raw(7))))

  expect_warning(resdf <- dbGetQuery(con, "SELECT * from t1"), "Cannot convert blob, NA is returned.")
  expect_equal(resdf[[1]], structure(NA_real_, units = "secs", class = c("hms", "difftime")))
})


test_that("roundtrip extended_types with dbWriteTable", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dates_times <- data.frame(
    some_date = as.Date(c("2000-01-01", "2000-02-03")),
    some_datetime = .POSIXct(1:2, tz = "UTC"),
    some_time = hms::hms(1:2)
  )

  dbWriteTable(con, "dates_times", dates_times)

  to_match <- dbReadTable(con, "dates_times")

  expect_identical(
    lapply(to_match, class),
    lapply(dates_times, class)
  )
})

test_that("dates, times and timestamps keep their exact values and warnings", {
  con <- dbConnect(SQLite(), ":memory:", extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, paste(
    "CREATE TABLE t",
    "(i INTEGER, d DATE, tm TIME, ts TIMESTAMP, dt DATETIME)"
  ))
  dbExecute(con, paste(
    "INSERT INTO t VALUES",
    "(1, '2024-01-02', '12:34:56.123456789', '2024-01-02 12:34:56.5',",
    "'1900-01-01 00:00:00'),",
    "(2, -1.9, -0.25, 1704198896.25, 4102444800),",
    "(3, 19725, '-01:30:00', -1, -2208988800.5),",
    "(4, x'07', 'x', 'not a timestamp', x'08'),",
    "(5, NULL, NULL, NULL, NULL),",
    "(6, 'not a date', x'09', '2024-01-02', '9999-12-31 23:59:59'),",
    "(7, '1400-01-01 12:00:00', '25:00:00.000001',",
    "'2024-01-02 12:00:00-02:00', ''),",
    "(8, NULL, '23:59:59.999999', '2024-01-02 12:34:56.999999', NULL)"
  ))

  warnings <- character()
  df <- withCallingHandlers(
    dbGetQuery(con, "SELECT d, tm, ts, dt FROM t ORDER BY i"),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  # Parsed text is a number of days, or of microseconds times 1e-6,
  # which differs from microseconds divided by 1e6 in row 8
  expect_identical(
    unclass(df$d),
    c(19724, -1, 19725, NA, NA, NA, -208188, NA)
  )
  expect_identical(as.numeric(df$tm), c(
    45296123456 * 1e-6, -0.25, -5400000000 * 1e-6, NA, NA, NA,
    90000000001 * 1e-6, 86399999999 * 1e-6
  ))
  # A negative offset reads as a fraction of a second
  expect_identical(as.numeric(df$ts), c(
    1704198896500000 * 1e-6, 1704198896.25, -1, NA, NA, NA,
    1704196800020000 * 1e-6, 1704198896999999 * 1e-6
  ))
  expect_identical(as.numeric(df$dt), c(
    -2208988800000000 * 1e-6, 4102444800, -2208988800.5, NA, NA,
    253402300799000000 * 1e-6, NA, NA
  ))
  expect_identical(attr(df$ts, "tzone"), "UTC")

  # One warning per value, row by row
  unknown <- "Unknown string format, NA is returned."
  blob <- "Cannot convert blob, NA is returned."
  expect_identical(
    warnings,
    c(blob, unknown, unknown, blob, unknown, blob, unknown, unknown)
  )
})

test_that("a date that can't be parsed fails a fetch if warnings are errors", {
  con <- dbConnect(SQLite(), ":memory:", extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE t (d DATE)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES ('2024-01-02'), ('oops'), ('2024-01-03')"
  ))

  res <- dbSendQuery(con, "SELECT d FROM t")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  withr::with_options(
    list(warn = 2),
    expect_error(dbFetch(res), "Unknown string format")
  )
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 0L)
})
