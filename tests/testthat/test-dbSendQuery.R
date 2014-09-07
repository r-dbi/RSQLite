context("dbSendQuery")

test_that("attempting to change schema with pending rows generates warning", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))
  
  df <- data.frame(a = letters, b = LETTERS, c = 1:26, stringsAsFactors = FALSE)
  dbWriteTable(con, "t1", df)
  
  rs <- dbSendQuery(con, "SELECT * FROM t1")
  row1 <- fetch(rs, n = 1)
  expect_equal(row1, df[1, ])
  
  expect_warning(dbSendQuery(con, "CREATE TABLE t2 (x text, y integer)"), 
    "pending rows")
})


test_that("simple position binding works", {
  con <- dbConnect(SQLite(), ":memory:")
  dbWriteTable(con, "t1", data.frame(x = 1, y = 2))

  dbGetPreparedQuery(con, "INSERT INTO t1 VALUES (?, ?)", 
    bind.data = data.frame(x = 2, y = 1))
  
  expect_equal(dbReadTable(con, "t1")$x, c(1, 2)) 
})

test_that("simple named binding works", {
  con <- dbConnect(SQLite(), ":memory:")
  dbWriteTable(con, "t1", data.frame(x = 1, y = 2))
  
  dbGetPreparedQuery(con, "INSERT INTO t1 VALUES (:x, :y)", 
    bind.data = data.frame(y = 1, x = 2))
  
  expect_equal(dbReadTable(con, "t1")$x, c(1, 2)) 
})

test_that("named binding errors if missing name", {
  con <- dbConnect(SQLite(), ":memory:")
  dbWriteTable(con, "t1", data.frame(x = 1, y = 2))
  
  expect_error(
    dbGetPreparedQuery(con, "INSERT INTO t1 VALUES (:x, :y)", 
      bind.data = data.frame(y = 1)), 
    "incomplete data binding"
  )
})

bind_select_setup <- function() {
  con <- dbConnect(SQLite())
  df <- data.frame(id = letters[1:5],
    x = 1:5,
    y = c(1L, 1L, 2L, 2L, 3L),
    stringsAsFactors = FALSE)
  
  dbWriteTable(con, "t1", df, row.names = FALSE)
  con
}

test_that("one row per bound select", {
  con <- bind_select_setup()
  
  got <- dbGetPreparedQuery(con, "select * from t1 where id = ?", 
    data.frame(id = c("e", "a", "c")))
  
  expect_equal(got$id, c("e", "a", "c"))
})

test_that("failed matches are silently dropped", {
  con <- bind_select_setup()
  sql <- "SELECT * FROM t1 WHERE id = ?"
  
  df1 <- dbGetPreparedQuery(con, sql, data.frame(id = "X"))
  expect_equal(nrow(df1), 0)
  expect_equal(names(df1), c("id", "x", "y"))
  
  df2 <- dbGetPreparedQuery(con, sql, data.frame(id = c("X", "Y")))
  expect_equal(nrow(df2), 0)
  expect_equal(names(df2), c("id", "x", "y"))
  
  df3 <- dbGetPreparedQuery(con, sql, data.frame(id = c("X", "a", "Y")))
  expect_equal(nrow(df3), 1)
  expect_equal(names(df3), c("id", "x", "y"))
})

test_that("NA matches NULL", {
  con <- bind_select_setup()
  dbGetQuery(con, "INSERT INTO t1 VALUES ('x', NULL, NULL)")
  
  got <- dbGetPreparedQuery(con, "SELECT id FROM t1 WHERE y IS :y",
    data.frame(y = NA_integer_))

  expect_equal(got$id, "x")
})
