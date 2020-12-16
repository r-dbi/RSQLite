context("extendedTypes")

test_that("Can handle dates", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "drop table if exists t1")
  dbExecute(con, "create table t1(dt DATE)")
  dbExecute(con, "insert into t1 values (1), (18612.2), ('2020-01-10') , ('not a date')")

  resdf <- dbGetQuery(con, 'SELECT * from t1')
  expect_that(resdf[[1]], equals(as.Date(c("1970-01-02", "2020-12-16", "2020-01-10", NA))))

  stmt <- dbSendQuery(con, "select * from t1")
  on.exit(dbClearResult(stmt), add = TRUE, after = FALSE)

  col_info = dbColumnInfo(stmt)
  expect_that(col_info$type, equals("Date"))

})

test_that("Can handle datetime", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "drop table if exists t1")
  dbExecute(con, "create table t1(dt DATETIME)")
  dbExecute(con, "insert into t1 values (1), (1608110307.2), ('2020-01-10 12:13:14') , ('not a date')")

  resdf <- dbGetQuery(con, 'SELECT * from t1')
  expect_that(resdf[[1]], equals(as.POSIXct(c("1970-01-01 00:00:01", "2020-12-16 09:18:27.2", "2020-01-10 12:13:14", NA), tz = "UTC")))

  stmt <- dbSendQuery(con, "select * from t1")
  on.exit(dbClearResult(stmt), add = TRUE, after = FALSE)

  col_info = dbColumnInfo(stmt)
  expect_that(col_info$type, equals("POSIXct"))

})



test_that("Can handle time", {
  con <- dbConnect(SQLite(), extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "drop table if exists t1")
  dbExecute(con, "create table t1(dt TIME)")
  dbExecute(con, "insert into t1 values (1), (-90000.2), ('25:12:13.123') , ('not a time')")

  resdf <- dbGetQuery(con, 'SELECT * from t1')
  expected_times <- structure(c(1, -90000.2, 90733.123, NA), units = "secs", class = c("hms", "difftime"))
  expect_that(resdf[[1]], equals(expected_times))


  stmt <- dbSendQuery(con, "select * from t1")
  on.exit(dbClearResult(stmt), add = TRUE, after = FALSE)

  col_info = dbColumnInfo(stmt)
  expect_that(col_info$type, equals("hms"))

})
