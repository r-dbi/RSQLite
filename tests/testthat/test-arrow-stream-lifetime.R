# An Arrow stream of read_arrow_stream() reads on
# after dbClearResult() and dbDisconnect(),
# and keeps the statement and the connection until it no longer needs them.

test_that("a stream reads on lazily after its result is cleared", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbWriteTable(con, "t", data.frame(a = 1:5))
  res <- dbSendQuery(con, "SELECT a FROM t")
  stream <- read_arrow_stream(res, 2)
  expect_equal(stream$get_next()$length, 2)

  dbClearResult(res)
  expect_false(dbIsValid(res))
  expect_warning(dbClearResult(res), "already closed")
  expect_error(dbFetch(res), "Invalid result set")

  # Chunk by chunk, also while other statements run on the connection
  expect_equal(nanoarrow::convert_array(stream$get_next())$a, 3:4)
  expect_equal(dbGetQuery(con, "SELECT count(*) AS n FROM t")$n, 5)
  expect_equal(nanoarrow::convert_array(stream$get_next())$a, 5L)
  expect_null(stream$get_next())
  expect_equal(stream$get_schema()$children$a$format, "l")
})

test_that("a stream of a result cleared before any fetch reads all rows", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  res <- dbSendQuery(con, "SELECT 1 AS x UNION ALL SELECT 2.5")
  stream <- read_arrow_stream(res)
  dbClearResult(res)
  expect_equal(nanoarrow::convert_array_stream(stream)$x, c(1, 2.5))
})

test_that("a stream reads on after its connection is closed", {
  skip_if_not_installed("nanoarrow")
  # The result is still open, and dbDisconnect() warns as before
  con <- dbConnect(SQLite(), ":memory:")
  res <- dbSendQuery(con, "SELECT 1 AS x UNION ALL SELECT 2")
  stream <- read_arrow_stream(res, 1)
  expect_equal(stream$get_next()$length, 1)
  expect_warning(dbDisconnect(con), "1 result in use")
  expect_false(dbIsValid(con))
  expect_equal(nanoarrow::convert_array(stream$get_next())$x, 2)
  expect_null(stream$get_next())
  dbClearResult(res)

  # A cleared result doesn't count as in use
  con <- dbConnect(SQLite(), ":memory:")
  res <- dbSendQuery(con, "SELECT 1 AS x UNION ALL SELECT 2")
  stream <- read_arrow_stream(res, 1)
  dbClearResult(res)
  expect_no_warning(dbDisconnect(con))
  expect_warning(dbDisconnect(con), "Already disconnected")
  expect_equal(nanoarrow::convert_array_stream(stream)$x, c(1, 2))
})

test_that("a result of a closed connection can't start a stream", {
  skip_if_not_installed("nanoarrow")
  con <- dbConnect(SQLite(), ":memory:")
  res <- dbSendQuery(con, "SELECT 1 AS x")
  suppressWarnings(dbDisconnect(con))
  expect_error(
    read_arrow_stream(res),
    "after its connection has been closed"
  )
  dbClearResult(res)
})

test_that("a stream reads on after R frees its result and connection", {
  skip_if_not_installed("nanoarrow")
  con <- dbConnect(SQLite(), ":memory:")
  dbWriteTable(con, "t", data.frame(a = 1:3))
  res <- dbSendQuery(con, "SELECT a FROM t")
  stream <- read_arrow_stream(res, 2)
  expect_equal(stream$get_next()$length, 2)
  # Not cleared, and the R object of the connection goes too
  expect_warning(dbDisconnect(con), "1 result in use")
  rm(res, con)
  gc()
  expect_equal(nanoarrow::convert_array(stream$get_next())$a, 3L)
  expect_null(stream$get_next())
})

test_that("the last stream to end or be released closes the statements and the connection", {
  skip_if_not_installed("nanoarrow")
  path <- withr::local_tempfile(fileext = ".sqlite")
  con <- dbConnect(SQLite(), path)
  dbWriteTable(con, "t", data.frame(a = 1:3))
  other <- dbConnect(SQLite(), path)
  withr::defer(dbDisconnect(other))
  insert <- function() {
    tryCatch(
      dbExecute(other, "INSERT INTO t VALUES (4)"),
      error = function(e) conditionMessage(e)
    )
  }

  # The connection holds a write transaction until it is closed
  dbBegin(con)
  dbExecute(con, "INSERT INTO t VALUES (10)")
  res <- dbSendQuery(con, "SELECT a FROM t")
  first <- read_arrow_stream(res, 1)
  expect_equal(first$get_next()$length, 1)
  dbClearResult(res)
  res <- dbSendQuery(con, "SELECT a FROM t")
  second <- read_arrow_stream(res, 1)
  dbClearResult(res)
  res <- dbSendQuery(con, "SELECT a FROM t")
  third <- read_arrow_stream(res, 1)
  dbClearResult(res)
  expect_no_warning(dbDisconnect(con))
  expect_equal(insert(), "database is locked")

  # Released before it has ended
  first$release()
  expect_equal(insert(), "database is locked")
  # Ended, then released
  expect_equal(nanoarrow::convert_array_stream(second)$a, c(1:3, 10L))
  expect_equal(insert(), "database is locked")
  second$release()
  expect_equal(insert(), "database is locked")
  # Freed by R's garbage collector
  expect_equal(third$get_next()$length, 1)
  rm(third)
  gc()
  # The close has rolled back the transaction
  expect_equal(insert(), 1)
  expect_equal(dbGetQuery(other, "SELECT a FROM t")$a, 1:4)
})

test_that("a stream that has ended lets the connection close", {
  skip_if_not_installed("nanoarrow")
  path <- withr::local_tempfile(fileext = ".sqlite")
  con <- dbConnect(SQLite(), path)
  dbWriteTable(con, "t", data.frame(a = 1:3))
  other <- dbConnect(SQLite(), path)
  withr::defer(dbDisconnect(other))

  dbBegin(con)
  dbExecute(con, "INSERT INTO t VALUES (10)")
  res <- dbSendQuery(con, "SELECT a FROM t")
  stream <- read_arrow_stream(res, 2)
  dbClearResult(res)
  dbDisconnect(con)
  expect_error(dbExecute(other, "INSERT INTO t VALUES (4)"), "locked")
  expect_equal(nanoarrow::convert_array_stream(stream)$a, c(1:3, 10L))
  # Before the stream is released
  expect_equal(dbExecute(other, "INSERT INTO t VALUES (4)"), 1)
  stream$release()
  expect_equal(dbGetQuery(other, "SELECT a FROM t")$a, 1:4)
})

test_that("streams of several results of one connection read independently", {
  skip_if_not_installed("nanoarrow")
  con <- dbConnect(SQLite(), ":memory:")
  dbWriteTable(con, "t", data.frame(a = 1:4))
  res <- dbSendQuery(con, "SELECT a FROM t")
  ones <- read_arrow_stream(res, 1)
  dbClearResult(res)
  res <- dbSendQuery(con, "SELECT a * 10 AS b FROM t")
  twos <- read_arrow_stream(res, 2)
  dbClearResult(res)
  dbDisconnect(con)

  expect_equal(nanoarrow::convert_array(ones$get_next())$a, 1L)
  expect_equal(nanoarrow::convert_array(twos$get_next())$b, c(10L, 20L))
  ones$release()
  expect_equal(nanoarrow::convert_array(twos$get_next())$b, c(30L, 40L))
  expect_null(twos$get_next())
})
