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
