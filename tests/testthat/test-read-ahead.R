# A fetch steps one row past the last row it returns,
# to tell whether the result is complete.
# If that step fails, the fetch still returns its rows,
# and the next fetch raises the error, which completes the result.

test_that("a fetch that returns the last row completes the result", {
  path <- withr::local_tempfile(fileext = ".sqlite")
  con <- dbConnect(SQLite(), path)
  on.exit(dbDisconnect(con), add = TRUE)
  dbWriteTable(con, "t", data.frame(a = 1:3))

  res <- dbSendQuery(con, "SELECT a FROM t")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  expect_equal(dbFetch(res, n = 3)$a, 1:3)
  expect_true(dbHasCompleted(res))

  # The statement is finished and holds no lock on the database
  con2 <- dbConnect(SQLite(), path)
  on.exit(dbDisconnect(con2), add = TRUE)
  sqliteSetBusyHandler(con2, 0L)
  expect_equal(dbExecute(con2, "INSERT INTO t VALUES (4)"), 1L)
})

test_that("an error after the last row of a fetch comes from the next fetch", {
  # Row 5 fails, so fetches of 1, 2 or 4 rows end right before it
  for (n in c(1L, 2L, 4L)) {
    local({
      con <- local_json_error_at_5()
      res <- dbSendQuery(con, "SELECT id, json(v) AS j FROM t1")
      withr::defer(dbClearResult(res))

      ids <- integer()
      for (i in seq_len(4L / n)) {
        out <- dbFetch(res, n = n)
        expect_equal(nrow(out), n)
        ids <- c(ids, out$id)
      }
      expect_equal(ids, 1:4)
      expect_false(dbHasCompleted(res))
      expect_equal(dbGetRowCount(res), 4L)

      expect_error(dbFetch(res, n = n), "malformed JSON")
      expect_true(dbHasCompleted(res))
      expect_equal(dbGetRowCount(res), 4L)
      expect_equal(nrow(dbFetch(res)), 0L)
      expect_equal(dbGetRowCount(res), 4L)
    })
  }
})

test_that("an error among the rows a fetch asks for comes from that fetch", {
  # A fetch can't return rows and raise an error:
  # returning rows 1 to 4 without the error would let `dbGetQuery()`
  # return a result cut short
  local({
    con <- local_json_error_at_5()
    res <- dbSendQuery(con, "SELECT id, json(v) AS j FROM t1")
    withr::defer(dbClearResult(res))
    expect_equal(dbFetch(res, n = 3)$id, 1:3)
    expect_error(dbFetch(res, n = 3), "malformed JSON")
  })

  for (n in c(5L, -1L)) {
    local({
      con <- local_json_error_at_5()
      res <- dbSendQuery(con, "SELECT id, json(v) AS j FROM t1")
      withr::defer(dbClearResult(res))
      expect_error(dbFetch(res, n = n), "malformed JSON")
    })
  }

  con <- local_json_error_at_5()
  expect_error(dbGetQuery(con, "SELECT json(v) FROM t1"), "malformed JSON")
})

test_that("dbGetQuery() with n drops an error after its rows, as LIMIT does", {
  con <- local_json_error_at_5()
  sql <- "SELECT id, json(v) AS j FROM t1"

  # The error is kept for a next fetch, and clearing the result drops it
  expect_silent(out <- dbGetQuery(con, sql, n = 4))
  expect_equal(out$id, 1:4)
  expect_equal(out, dbGetQuery(con, paste(sql, "LIMIT 4")))
})

test_that("an error after the last row of a fetch keeps it across parameter sets", {
  # Each parameter set returns one row, and the fifth fails
  for (n in c(1L, 4L)) {
    local({
      con <- local_json_error_at_5()
      res <- dbSendQuery(con, "SELECT id, json(v) AS j FROM t1 WHERE id = ?")
      withr::defer(dbClearResult(res))
      dbBind(res, list(1:6))

      ids <- integer()
      for (i in seq_len(4L / n)) {
        ids <- c(ids, dbFetch(res, n = n)$id)
      }
      expect_equal(ids, 1:4)
      expect_false(dbHasCompleted(res))
      expect_error(dbFetch(res, n = n), "malformed JSON")
      expect_true(dbHasCompleted(res))
      expect_equal(dbGetRowCount(res), 4L)
    })
  }

  # The third parameter set fails to bind
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)
  res <- dbSendQuery(con, "SELECT ? AS x")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)
  dbBind(res, list(list(as.raw(1), as.raw(2), "a")))

  expect_equal(dbFetch(res, n = 2)$x, blob::blob(as.raw(1), as.raw(2)))
  expect_false(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 2L)
  expect_error(dbFetch(res, n = 2), "raw vectors")
  expect_true(dbHasCompleted(res))
  expect_equal(nrow(dbFetch(res)), 0L)
  expect_equal(dbGetRowCount(res), 2L)
})

test_that("a value SQLite refuses to bind after a fetch comes from the next fetch", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)
  connection_limit_length(con@ptr, 30L)

  res <- dbSendQuery(con, "SELECT :x AS x")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  # The second parameter set is over the length limit
  dbBind(res, list(x = c("a", strrep("a", 31), "c")))
  expect_identical(dbFetch(res, n = 1)$x, "a")
  expect_false(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 1L)

  expect_error(
    dbFetch(res, n = 1),
    "Can't bind parameter 1 (:x) in row 2: string or blob too big",
    fixed = TRUE
  )

  # The error completes the result, and no fetch reads the reset statement
  expect_true(dbHasCompleted(res))
  expect_equal(nrow(dbFetch(res)), 0L)
  expect_equal(dbGetRowCount(res), 1L)

  # A new dbBind() starts afresh, with no error kept
  dbBind(res, list(x = "d"))
  expect_identical(dbFetch(res)$x, "d")
  expect_true(dbHasCompleted(res))
})

test_that("an error kept for the next fetch keeps SQLite's message", {
  con <- local_json_error_at_5()
  res <- dbSendQuery(con, "SELECT id, json(v) AS j FROM t1")
  withr::defer(dbClearResult(res))
  expect_equal(dbFetch(res, n = 4)$id, 1:4)

  # Statements that fail later overwrite the message of the connection.
  # `dbSendQuery()` would close `res`, so they are sent internally.
  expect_error(result_create(con@ptr, "SELECT x FROM nothere"), "no such table")
  expect_error(
    result_create(con@ptr, "SELECT abs(-9223372036854775807 - 1)"),
    "integer overflow"
  )

  expect_error(dbFetch(res), "malformed JSON")
})

test_that("an SQLite message is not used as a format string", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)
  dbExecute(
    con,
    'CREATE TABLE c (x INTEGER CONSTRAINT "positive %d%d%x" CHECK (x > 0))'
  )
  msg <- "CHECK constraint failed: positive %d%d%x"

  res <- dbSendQuery(con, "INSERT INTO c VALUES (?) RETURNING x")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  # The second parameter set fails while a fetch steps on
  dbBind(res, list(c(1L, -1L)))
  expect_error(dbFetch(res), msg, fixed = TRUE)

  # The second parameter set fails in the step past the last row of a fetch
  dbBind(res, list(c(2L, -1L)))
  expect_equal(dbFetch(res, n = 1)$x, 2L)
  expect_error(dbFetch(res, n = 1), msg, fixed = TRUE)
})

test_that("the structure of a result stays available with an error kept", {
  con <- local_json_error_at_5()
  res <- dbSendQuery(con, "SELECT id, json(v) AS j FROM t1")
  withr::defer(dbClearResult(res))

  expect_equal(dbFetch(res, n = 4)$id, 1:4)

  # Neither reads a row, so the error stays for the next fetch
  out <- dbFetch(res, n = 0)
  expect_equal(nrow(out), 0L)
  expect_named(out, c("id", "j"))
  info <- dbColumnInfo(res)
  expect_equal(info$name, c("id", "j"))
  expect_equal(info$type, c("integer", "character"))

  expect_error(dbFetch(res), "malformed JSON")
  expect_true(dbHasCompleted(res))
})

test_that("a new dbBind() drops the error kept from the previous one", {
  con <- local_json_error_at_5()
  res <- dbSendQuery(con, "SELECT id, json(v) AS j FROM t1 WHERE id >= ?")
  withr::defer(dbClearResult(res))

  dbBind(res, list(1L))
  expect_equal(dbFetch(res, n = 4)$id, 1:4)

  dbBind(res, list(6L))
  expect_equal(dbFetch(res)$id, 6L)
  expect_true(dbHasCompleted(res))
})
