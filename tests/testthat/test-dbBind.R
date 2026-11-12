# A list of parameters binds one parameter set per element of its vectors,
# and the statement runs once for each set.

test_that("parameters that don't match the placeholders give errors", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  bind_error <- function(sql, params) {
    tryCatch(dbGetQuery(con, sql, params = params), error = conditionMessage)
  }

  # Named placeholders take the parameters by name
  expect_identical(
    bind_error("SELECT :a, :b", list(b = 1)),
    "No value given for placeholder a"
  )
  expect_identical(
    bind_error("SELECT :a, :b", list(1, 2)),
    "No value given for placeholder a, b"
  )
  expect_identical(
    bind_error("SELECT :a", list(a = 1, b = 2, c = 3)),
    "Named parameters not used in query: b, c"
  )

  # Anonymous and numbered placeholders take them by position
  expect_identical(
    bind_error("SELECT ?", list(a = 1)),
    "Cannot use named parameters for anonymous/numbered placeholders"
  )
  expect_identical(
    bind_error("SELECT ?1", list(a = 1)),
    "Cannot use named parameters for anonymous/numbered placeholders"
  )
  expect_identical(
    bind_error("SELECT ?", list(1, 2)),
    "Query requires 1 params; 2 supplied."
  )
  expect_identical(
    bind_error("SELECT ?, :a", list(1, 2)),
    "Cannot mix anonymous and named/numbered placeholders in query"
  )
  expect_identical(
    bind_error("SELECT ?1, :a", list(1, 2)),
    "Cannot mix numbered and named placeholders in query"
  )

  # A query without placeholders takes no parameters,
  # and those of an unnamed list count as named parameters it doesn't use
  expect_identical(
    bind_error("SELECT 1", list()),
    "Query does not require parameters."
  )
  expect_identical(
    bind_error("SELECT 1", list(a = 1)),
    "Named parameters not used in query: a"
  )
  expect_identical(
    bind_error("SELECT 1", list(1, 2)),
    "Named parameters not used in query: "
  )
})

test_that("named parameters bind to their placeholders in any order", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  out <- dbGetQuery(
    con,
    "SELECT :a AS a, $b AS b, @c AS c",
    params = list(c = 3, a = 1, b = 2)
  )
  expect_equal(out, data.frame(a = 1, b = 2, c = 3))

  # Named parameters that the query doesn't use only warn,
  # as for `dbGetPreparedQuery()`
  res <- dbSendQuery(con, "SELECT :a AS a")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)
  expect_warning(
    db_bind(res, list(b = 2, a = 1), allow_named_superset = TRUE),
    "^Named parameters not used in query: b$"
  )
  expect_equal(dbFetch(res)$a, 1)
})

test_that("values that can't be bound give errors", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  res <- dbSendQuery(con, "SELECT ? AS x")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  expect_error(
    dbBind(res, list(1i)),
    "Don't know how to handle parameter of type complex.",
    fixed = TRUE
  )
  expect_error(dbFetch(res), "needs to be bound")
  expect_error(
    dbBind(res, list(list(1))),
    "Can only bind lists of raw vectors (or NULL)",
    fixed = TRUE
  )
  expect_error(dbFetch(res), "needs to be bound")

  dbBind(res, list(1L))
  expect_equal(dbFetch(res)$x, 1L)
})

test_that("each parameter set runs the statement once", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE t (x INTEGER)")
  expect_equal(
    dbExecute(con, "INSERT INTO t VALUES (?)", params = list(1:3)),
    3L
  )

  # A set returns any number of rows
  out <- dbGetQuery(
    con,
    "SELECT x FROM t WHERE x >= ? ORDER BY x",
    params = list(c(3L, 4L, 2L))
  )
  expect_equal(out$x, c(3L, 2L, 3L))

  # Fetches go on across the sets
  res <- dbSendQuery(con, "SELECT x FROM t WHERE x <= ? ORDER BY x")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)
  dbBind(res, list(c(2L, 0L, 3L)))
  expect_equal(dbFetch(res, n = 3)$x, c(1L, 2L, 1L))
  expect_false(dbHasCompleted(res))
  expect_equal(dbFetch(res, n = 3)$x, 2:3)
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 5L)
})

test_that("each type of vector binds its values and missing values", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  out <- dbGetQuery(
    con,
    "SELECT ? AS l, ? AS i, ? AS d, ? AS s, ? AS b, ? AS i64",
    params = list(
      c(TRUE, NA, FALSE),
      c(1L, NA, 3L),
      c(1.5, NA, 3.5),
      c("a", NA, "c"),
      blob::blob(as.raw(1), NULL, as.raw(3)),
      bit64::as.integer64(c(2^40, NA, 3))
    )
  )
  expect_equal(out$l, c(1L, NA, 0L))
  expect_equal(out$i, c(1L, NA, 3L))
  expect_equal(out$d, c(1.5, NA, 3.5))
  expect_equal(out$s, c("a", NA, "c"))
  expect_equal(out$b, blob::blob(as.raw(1), NULL, as.raw(3)))
  expect_equal(out$i64, bit64::as.integer64(c(2^40, NA, 3)))
})

test_that("parameters of length zero don't run the statement", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE t (x)")
  expect_equal(
    dbExecute(con, "INSERT INTO t VALUES (?)", params = list(integer())),
    0L
  )
  expect_equal(dbGetQuery(con, "SELECT count(*) AS n FROM t")$n, 0L)

  res <- dbSendQuery(con, "SELECT ? AS x")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)
  dbBind(res, list(character()))
  expect_true(dbHasCompleted(res))
  out <- dbFetch(res)
  expect_equal(nrow(out), 0L)
  expect_named(out, "x")
  expect_equal(dbGetRowCount(res), 0L)
  expect_equal(dbGetRowsAffected(res), 0L)

  dbBind(res, list("a"))
  expect_false(dbHasCompleted(res))
  expect_equal(dbFetch(res)$x, "a")
})

# The fetch that binds a later set that fails returns the rows before it,
# see test-read-ahead.R
test_that("a later parameter set that fails to bind keeps the changes before it", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE t (x BLOB)")
  res <- dbSendStatement(con, "INSERT INTO t VALUES (?)")

  expect_error(
    dbBind(res, list(list(as.raw(1), as.raw(2), "c", as.raw(4)))),
    "Can only bind lists of raw vectors (or NULL)",
    fixed = TRUE
  )
  expect_equal(dbGetRowsAffected(res), 2L)
  expect_error(dbFetch(res), "needs to be bound")
  dbClearResult(res)

  expect_equal(
    dbGetQuery(con, "SELECT x FROM t")$x,
    blob::blob(as.raw(1), as.raw(2))
  )
})

test_that("a new bind replaces the parameter sets left", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  res <- dbSendQuery(con, "SELECT ? AS x")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  dbBind(res, list(1:3))
  expect_equal(dbFetch(res, n = 1)$x, 1L)

  dbBind(res, list(5:6))
  expect_equal(dbGetRowCount(res), 0L)
  expect_equal(dbFetch(res)$x, 5:6)
  expect_true(dbHasCompleted(res))

  dbBind(res, list(7L))
  expect_false(dbHasCompleted(res))
  expect_equal(dbFetch(res)$x, 7L)
  expect_equal(dbGetRowCount(res), 1L)
})

test_that("bound parameters stay valid across fetches", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  res <- dbSendQuery(con, "SELECT ? AS s, ? AS d")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  # Only the result refers to the vectors made here
  dbBind(res, list(as.character(1:1000), as.numeric(1:1000) / 2))

  out <- NULL
  while (!dbHasCompleted(res)) {
    gc()
    out <- rbind(out, dbFetch(res, n = 100))
  }
  expect_equal(out$s, as.character(1:1000))
  expect_equal(out$d, (1:1000) / 2)
})

test_that("a handler can't bind a result while its fetch runs", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE m (x)")
  dbExecute(con, "INSERT INTO m VALUES ('a'), (2)")

  res <- dbSendQuery(con, "SELECT x FROM m WHERE x IS NOT ?")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)
  dbBind(res, list(c(0, 2)))

  # The mixed types give a warning once the rows of both sets are read
  bound <- NULL
  out <- withCallingHandlers(
    dbFetch(res),
    warning = function(w) {
      bound <<- tryCatch(dbBind(res, list(0)), error = conditionMessage)
      invokeRestart("muffleWarning")
    }
  )
  expect_match(
    bound,
    "Can't use a result while one of its fetches or binds is running"
  )
  expect_equal(out$x, c("a", "2", "a"))
  expect_true(dbHasCompleted(res))

  dbBind(res, list(2))
  expect_equal(dbFetch(res)$x, "a")
})
