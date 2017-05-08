context("dbSendQuery")

bind_select_setup <- function() {
  con <- dbConnect(SQLite())

  df <- data.frame(
    id = letters[1:5],
    x = 1:5,
    y = c(1L, 1L, 2L, 2L, 3L),
    stringsAsFactors = FALSE
  )

  dbWriteTable(con, "t1", df, row.names = FALSE)
  con
}

test_that("attempting to change schema with pending rows generates warning", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  df <- data.frame(a = letters, b = LETTERS, c = 1:26, stringsAsFactors = FALSE)
  dbWriteTable(con, "t1", df)

  rs <- dbSendQuery(con, "SELECT * FROM t1")
  row1 <- dbFetch(rs, n = 1)
  expect_equal(row1, df[1, ])

  expect_warning(rs <- dbSendStatement(con, "CREATE TABLE t2 (x text, y integer)"),
    "pending rows")
  dbClearResult(rs)
})


test_that("simple position binding works", {
  memoise::forget(warning_once)
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "t1", data.frame(x = 1, y = 2))

  expect_warning(
    dbGetPreparedQuery(con, "INSERT INTO t1 VALUES (?, ?)",
      bind.data = data.frame(x = 2, y = 1)),
    "deprecated")

  expect_equal(dbReadTable(con, "t1")$x, c(1, 2))
})

test_that("simple named binding works", {
  memoise::forget(warning_once)
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "t1", data.frame(x = 1, y = 2))

  expect_warning(
    dbGetPreparedQuery(con, "INSERT INTO t1 VALUES (:x, :y)",
      bind.data = data.frame(y = 1, x = 2)),
    "deprecated")

  expect_equal(dbReadTable(con, "t1")$x, c(1, 2))
})

test_that("named binding errors if missing name", {
  con <- dbConnect(SQLite(), ":memory:")
  dbWriteTable(con, "t1", data.frame(x = 1, y = 2))
  on.exit(dbDisconnect(con), add = TRUE)

  expect_error(
    expect_warning(
      dbGetPreparedQuery(con, "INSERT INTO t1 VALUES (:x, :y)",
        bind.data = data.frame(y = 1)),
      "deprecated"),
    "No value given for placeholder"
  )
})

test_that("one row per bound select, with factor", {
  memoise::forget(warning_once)
  con <- bind_select_setup()
  on.exit(dbDisconnect(con), add = TRUE)

  id_frame <- data.frame(id = c("e", "a", "c"))

  expect_warning(
    got <- dbGetPreparedQuery(con, "select * from t1 where id = ?", id_frame),
    "deprecated")

  expect_equal(got$id, c("e", "a", "c"))
})

test_that("one row per bound select", {
  memoise::forget(warning_once)
  con <- bind_select_setup()
  on.exit(dbDisconnect(con), add = TRUE)

  id_frame <- data.frame(id = I(c("e", "a", "c")))

  expect_warning(
    got <- dbGetPreparedQuery(con, "select * from t1 where id = ?", id_frame),
    "deprecated")

  expect_equal(got$id, c("e", "a", "c"))
})

test_that("failed matches are silently dropped", {
  con <- bind_select_setup()
  on.exit(dbDisconnect(con), add = TRUE)
  sql <- "SELECT * FROM t1 WHERE id = ?"

  memoise::forget(warning_once)
  expect_warning(
    df1 <- dbGetPreparedQuery(con, sql, data.frame(id = I("X"))),
    "deprecated")
  expect_equal(nrow(df1), 0)
  expect_equal(names(df1), c("id", "x", "y"))

  memoise::forget(warning_once)
  expect_warning(
    df2 <- dbGetPreparedQuery(con, sql, data.frame(id = I(c("X", "Y")))),
    "deprecated")
  expect_equal(nrow(df2), 0)
  expect_equal(names(df2), c("id", "x", "y"))

  memoise::forget(warning_once)
  expect_warning(
    df3 <- dbGetPreparedQuery(con, sql, data.frame(id = I(c("X", "a", "Y")))),
    "deprecated")
  expect_equal(nrow(df3), 1)
  expect_equal(names(df3), c("id", "x", "y"))
})

test_that("NA matches NULL", {
  memoise::forget(warning_once)
  con <- bind_select_setup()
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "INSERT INTO t1 VALUES ('x', NULL, NULL)")

  expect_warning(
    got <- dbGetPreparedQuery(con, "SELECT id FROM t1 WHERE y IS :y",
                              data.frame(y = NA_integer_)),
    "deprecated")

  expect_equal(got$id, "x")
})
