test_that("warning on dbFetch if result set open", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))

  res <- dbSendQuery(con, "SELECT 1;")
  expect_false(dbHasCompleted(res))

  expect_warning(dbGetQuery(con, "SELECT 1;"), "pending rows")

  expect_warning(dbClearResult(res), "Expired")
})

test_that("accessing cleared result throws error", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))

  res <- dbSendQuery(con, "SELECT 1;")
  dbClearResult(res)

  expect_error(dbFetch(res), "Invalid result set")
  expect_error(dbGetInfo(res), "closed")
})

test_that("a result is valid until it is cleared, and can be cleared once", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  res <- dbSendQuery(con, "SELECT 1 AS a")
  expect_true(dbIsValid(res))
  expect_true(dbClearResult(res))
  expect_false(dbIsValid(res))

  expect_warning(
    out <- dbClearResult(res),
    "^Expired, result set already closed$"
  )
  expect_true(out)
  expect_false(dbIsValid(res))
})

test_that("a cleared result fails with the same error everywhere", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  res <- dbSendQuery(con, "SELECT ? AS a")
  dbClearResult(res)

  invalid <- "^Invalid result set$"
  expect_error(dbFetch(res), invalid, class = "simpleError")
  expect_error(dbBind(res, list(1)), invalid, class = "simpleError")
  expect_error(dbHasCompleted(res), invalid, class = "simpleError")
  expect_error(dbGetRowCount(res), invalid, class = "simpleError")
  expect_error(dbGetRowsAffected(res), invalid, class = "simpleError")
  expect_error(dbColumnInfo(res), invalid, class = "simpleError")
  expect_error(dbGetInfo(res), "^Expired, result set already closed$")
})

test_that("sending a query clears the open result of the connection", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  res <- dbSendQuery(con, "SELECT 1 AS a")
  expect_warning(
    res2 <- dbSendQuery(con, "SELECT 2 AS b"),
    "^Closing open result set, pending rows$"
  )
  on.exit(dbClearResult(res2), add = TRUE, after = FALSE)

  expect_false(dbIsValid(res))
  expect_error(dbFetch(res), "^Invalid result set$")
  expect_true(dbIsValid(res2))
  expect_equal(dbFetch(res2), data.frame(b = 2L))
})

test_that("a result collected without being cleared lets go of its connection", {
  con <- dbConnect(SQLite(), ":memory:")

  # The connection keeps the result objects of dbSendQuery(),
  # so the external pointer is created and dropped alone
  ptr <- result_create(con@ptr, "SELECT 1 AS a")
  rm(ptr)
  invisible(gc())

  expect_equal(dbGetQuery(con, "SELECT 2 AS b"), data.frame(b = 2L))
  # No result is left in use
  expect_silent(dbDisconnect(con))
  expect_false(dbIsValid(con))
})

test_that("disconnecting with an open result warns, the result holds the connection", {
  con <- dbConnect(SQLite(), ":memory:")
  res <- dbSendQuery(con, "SELECT 1 AS a")
  ptr <- result_create(con@ptr, "SELECT 2 AS b")

  expect_warning(
    dbDisconnect(con),
    paste0(
      "^There are 2 result in use\\. ",
      "The connection will be released when they are closed$"
    )
  )
  expect_false(dbIsValid(con))
  expect_true(dbIsValid(res))

  expect_equal(dbFetch(res), data.frame(a = 1L))
  expect_silent(dbClearResult(res))
  expect_false(dbIsValid(res))

  # The last result lets go of the connection when collected
  rm(ptr)
  expect_silent(invisible(gc()))
})

test_that("a handler of a fetch can't clear its result, which can be cleared after", {
  con <- dbConnect(SQLite(), ":memory:", extended_types = TRUE)
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE d (x DATE)")
  dbExecute(con, "INSERT INTO d VALUES ('oops'), ('2026-01-02')")
  res <- dbSendQuery(con, "SELECT x FROM d")

  cleared <- NULL
  out <- withCallingHandlers(
    dbFetch(res),
    warning = function(w) {
      cleared <<- tryCatch(dbClearResult(res), error = conditionMessage)
      invokeRestart("muffleWarning")
    }
  )
  expect_equal(
    cleared,
    paste(
      "Can't clear a result while one of its fetches or binds is running,",
      "as from a handler of a warning that it raised."
    )
  )
  expect_equal(out$x, as.Date(c(NA, "2026-01-02")))

  expect_true(dbIsValid(res))
  expect_true(dbClearResult(res))
  expect_false(dbIsValid(res))
})
