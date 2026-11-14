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

test_that("Datetime applies a UTC offset as SQLite does (#877)", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  values <- c(
    "2024-01-02 12:00:00-05:00",
    "2024-01-02 12:00:00-05:30",
    "2024-01-02 12:00-02:00",
    "2024-01-02 12:00:00.5-02:00",
    "2024-01-02 23:00:00-02:00",
    "2024-01-02 12:00:00+02:00",
    "2024-01-02 12:00:00Z",
    "2024-01-02 12:00:00 -02:00 "
  )
  dbExecute(con, "create table t1(id INTEGER, dt DATETIME)")
  dbAppendTable(con, "t1", data.frame(id = seq_along(values), dt = values))

  resdf <- dbGetQuery(con, "SELECT dt, datetime(dt, 'subsec') AS sqlite FROM t1 ORDER BY id")
  # Seconds after 2024-01-02 12:00:00 UTC
  secs <- c(18000, 19800, 7200, 7200.5, 46800, -7200, 0, 7200)
  expect_equal(resdf$dt, .POSIXct(1704196800 + secs, tz = "UTC"))
  expect_equal(resdf$dt, as.POSIXct(resdf$sqlite, tz = "UTC"))
})

test_that("Datetime with an offset SQLite does not read gives NA (#877)", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  values <- c(
    "2024-01-02 12:00:00-0500",
    "2024-01-02 12:00:00-15:00",
    "2024-01-02 12:00:00-05:00x"
  )
  dbExecute(con, "create table t1(id INTEGER, dt DATETIME)")
  dbAppendTable(con, "t1", data.frame(id = seq_along(values), dt = values))

  warnings <- capture_warnings(
    resdf <- dbGetQuery(con, "SELECT dt, datetime(dt) IS NULL AS sqlite_na FROM t1 ORDER BY id")
  )
  expect_equal(warnings, rep("Unknown string format, NA is returned.", 3))
  expect_equal(resdf$dt, .POSIXct(rep(NA_real_, 3), tz = "UTC"))
  expect_equal(resdf$sqlite_na, rep(1L, 3))
})

test_that("Time applies a UTC offset as SQLite does (#877)", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  values <- c(
    "12:00:00-02:00",
    "12:00:00.25-02:00",
    "23:00:00-02:00",
    "01:00:00+02:00",
    "12:00Z",
    "24:00:00+00:00"
  )
  dbExecute(con, "create table t1(id INTEGER, tm TIME)")
  dbAppendTable(con, "t1", data.frame(id = seq_along(values), tm = values))

  resdf <- dbGetQuery(con, "SELECT tm, time(tm, 'subsec') AS sqlite FROM t1 ORDER BY id")
  expected_times <- structure(
    c(50400, 50400.25, 3600, 82800, 43200, 0),
    units = "secs",
    class = c("hms", "difftime")
  )
  expect_equal(resdf$tm, expected_times)
  expect_equal(resdf$sqlite, c("14:00:00.000", "14:00:00.250", "01:00:00.000", "23:00:00.000", "12:00:00.000", "00:00:00.000"))
})

test_that("Time with an offset SQLite does not read gives NA (#877)", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  # Boost reads these as durations, SQLite's `time()` rejects them
  values <- c(
    "12:00:00-0200",
    "25:00:00-02:00",
    "100:00:00-01:00",
    "12:60:00-01:00",
    "-01:00:00+00:00",
    "24:00:01+00:00"
  )
  dbExecute(con, "create table t1(id INTEGER, tm TIME)")
  dbAppendTable(con, "t1", data.frame(id = seq_along(values), tm = values))

  warnings <- capture_warnings(
    resdf <- dbGetQuery(con, "SELECT tm, time(tm) IS NULL AS sqlite_na FROM t1 ORDER BY id")
  )
  expect_equal(warnings, rep("Unknown string format, NA is returned.", 6))
  expect_equal(resdf$tm, structure(rep(NA_real_, 6), units = "secs", class = c("hms", "difftime")))
  expect_equal(resdf$sqlite_na, rep(1L, 6))
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

test_that("an error from a warning handler on a new column storage propagates (#879)", {
  con <- dbConnect(SQLite(), ":memory:", extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE d (x DATE)")
  dbExecute(con, "INSERT INTO d VALUES ('oops'), ('2026-01-02')")

  res <- dbSendQuery(con, "SELECT x FROM d")
  expect_error(
    withCallingHandlers(
      dbFetch(res),
      warning = function(w) stop("from handler")
    ),
    "from handler"
  )
  dbClearResult(res)

  expect_warning(
    out <- dbGetQuery(con, "SELECT x FROM d"),
    "Unknown string format, NA is returned."
  )
  expect_identical(out$x, as.Date(c(NA, "2026-01-02")))
})
