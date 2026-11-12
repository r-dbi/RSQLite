test_that("dbGetRowCount() goes on beyond INT_MAX as a double", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)
  dbWriteTable(con, "t", data.frame(a = 1:5))
  rs <- dbSendQuery(con, "SELECT a FROM t ORDER BY a")
  on.exit(dbClearResult(rs), add = TRUE, after = FALSE)

  expect_equal(nrow(dbFetch(rs, n = 1)), 1L)
  expect_identical(dbGetRowCount(rs), 1L)
  expect_error(result_set_rows_fetched(rs@ptr, NA_real_), "whole number")
  # As if 2^31 - 2 rows had been fetched
  result_set_rows_fetched(rs@ptr, 2^31 - 2)
  expect_equal(nrow(dbFetch(rs, n = 1)), 1L)
  expect_identical(dbGetRowCount(rs), .Machine$integer.max)
  expect_equal(nrow(dbFetch(rs, n = 2)), 2L)
  expect_identical(dbGetRowCount(rs), 2^31 + 1)
  expect_equal(nrow(dbFetch(rs)), 1L)
  expect_identical(dbGetRowCount(rs), 2^31 + 2)
})

test_that("dbGetRowsAffected() goes on beyond INT_MAX as a double", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)
  dbExecute(con, "CREATE TABLE t (a INTEGER)")
  # SQLite counts the changes of a statement with RETURNING
  # once the statement is done, after its last row
  rs <- dbSendQuery(con, "INSERT INTO t VALUES (1), (2), (3) RETURNING a")
  on.exit(dbClearResult(rs), add = TRUE, after = FALSE)

  expect_identical(dbGetRowsAffected(rs), 0L)
  # As if the statement had changed 2^31 - 1 rows.
  # The hook moves the start of the count, not SQLite's total of changes,
  # so this covers the R type and the 64-bit arithmetic only:
  # only the gated test below catches a return to the 32-bit total.
  result_set_rows_affected(rs@ptr, 2^31 - 1)
  expect_identical(dbGetRowsAffected(rs), .Machine$integer.max)
  expect_equal(nrow(dbFetch(rs)), 3L)
  expect_identical(dbGetRowsAffected(rs), 2^31 + 2)
})

test_that("dbGetRowCount() counts 2^31 rows fetched in chunks", {
  skip_if_not(
    Sys.getenv("RSQLITE_TEST_INT_MAX_ROWS") == "true",
    "fetches 2^31 rows for minutes, set RSQLITE_TEST_INT_MAX_ROWS=true to run"
  )
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)
  # 2^31 + 1 rows, generated without storing them
  rs <- dbSendQuery(
    con,
    "WITH RECURSIVE r(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM r WHERE i <= ?)
    SELECT NULL AS x FROM r",
    params = list(2^31)
  )
  on.exit(dbClearResult(rs), add = TRUE, after = FALSE)

  int_max <- .Machine$integer.max
  while (dbGetRowCount(rs) < int_max - 1e6) {
    dbFetch(rs, n = 1e6)
  }
  dbFetch(rs, n = int_max - 1L - dbGetRowCount(rs))
  expect_identical(dbGetRowCount(rs), int_max - 1L)
  expect_equal(nrow(dbFetch(rs, n = 1)), 1L)
  expect_identical(dbGetRowCount(rs), int_max)
  expect_equal(nrow(dbFetch(rs, n = 1)), 1L)
  expect_identical(dbGetRowCount(rs), 2^31)
  expect_equal(nrow(dbFetch(rs)), 1L)
  expect_identical(dbGetRowCount(rs), 2^31 + 1)
  expect_true(dbHasCompleted(rs))
})

test_that("dbExecute() counts 2^31 rows changed by one statement", {
  skip_if_not(
    Sys.getenv("RSQLITE_TEST_INT_MAX_ROWS") == "true",
    "changes 2^31 rows for minutes, set RSQLITE_TEST_INT_MAX_ROWS=true to run"
  )
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)
  dbExecute(
    con,
    "CREATE TABLE t AS
    WITH RECURSIVE r(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM r WHERE i < ?)
    SELECT i AS a FROM r",
    params = list(2^20)
  )

  # 2^11 + 1 executions of 2^20 changes each
  n <- dbExecute(con, "UPDATE t SET a = a + ?", params = list(rep(1L, 2^11 + 1)))
  expect_identical(n, 2^31 + 2^20)
})
