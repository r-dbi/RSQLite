test_that("dbBind() refuses text over the length limit", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)
  connection_limit_length(con@ptr, 30L)

  res <- dbSendQuery(con, "SELECT ? AS x")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  expect_error(
    dbBind(res, list(strrep("a", 31))),
    "Can't bind parameter 1 in row 1: string or blob too big",
    fixed = TRUE
  )

  dbBind(res, list(strrep("a", 30)))
  expect_identical(dbFetch(res)$x, strrep("a", 30))
})

test_that("dbBind() refuses a blob over the length limit", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)
  connection_limit_length(con@ptr, 30L)

  res <- dbSendQuery(con, "SELECT ? AS x")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  expect_error(
    dbBind(res, list(list(as.raw(seq_len(31))))),
    "Can't bind parameter 1 in row 1: string or blob too big",
    fixed = TRUE
  )

  dbBind(res, list(list(as.raw(seq_len(30)))))
  expect_identical(dbFetch(res)$x[[1]], as.raw(seq_len(30)))
})

test_that("dbBind() names the parameter and the row it can't bind", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)
  connection_limit_length(con@ptr, 30L)

  res <- dbSendQuery(con, "SELECT :y AS y, :x AS x")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  dbBind(res, list(x = c("a", strrep("a", 31)), y = 1:2))
  expect_error(
    dbFetch(res),
    "Can't bind parameter 2 (:x) in row 2: string or blob too big",
    fixed = TRUE
  )
  expect_true(dbHasCompleted(res))
  expect_equal(nrow(dbFetch(res)), 0L)

  dbBind(res, list(x = "b", y = 3L))
  expect_identical(dbFetch(res), data.frame(y = 3L, x = "b"))
})

test_that("a failed dbBind() leaves a result that can be cleared", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)
  connection_limit_length(con@ptr, 30L)

  res <- dbSendQuery(con, "SELECT ? AS x")
  expect_error(dbBind(res, list(strrep("a", 31))), "too big")
  expect_silent(dbClearResult(res))
  expect_false(dbIsValid(res))
})

test_that("dbExecute() refuses a value over the length limit", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)
  dbExecute(con, "CREATE TABLE t (x TEXT)")
  connection_limit_length(con@ptr, 30L)

  expect_error(
    dbExecute(con, "INSERT INTO t VALUES (?)", params = list(strrep("a", 31))),
    "string or blob too big",
    fixed = TRUE
  )
  expect_identical(dbGetQuery(con, "SELECT COUNT(*) AS n FROM t")$n, 0L)
})

test_that("a failed dbBind() leaves a fetched result unbound", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)
  connection_limit_length(con@ptr, 30L)

  res <- dbSendQuery(con, "SELECT ? AS x")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  dbBind(res, list("ok"))
  expect_identical(dbFetch(res)$x, "ok")
  expect_equal(dbGetRowCount(res), 1L)

  expect_error(dbBind(res, list(strrep("a", 31))), "too big")
  expect_error(dbFetch(res), "needs to be bound")
  expect_equal(dbGetRowCount(res), 0L)

  dbBind(res, list("again"))
  expect_identical(dbFetch(res)$x, "again")
})
