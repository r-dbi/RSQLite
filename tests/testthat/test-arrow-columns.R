# Arrow arrays built from the integer, real and NULL columns of a result,
# through the internal result_fetch_arrow_chunk().
# Each chunk is compared with what dbFetch() returns for the same rows.
# Text and blobs are in test-arrow-text.R.

test_that("integer, real and NULL columns become int64, double and null", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, i, r, n)")
  dbExecute(
    con,
    "INSERT INTO t VALUES (1, 1, 1.5, NULL), (2, -2, -0.25, NULL)"
  )

  chunks <- expect_same_chunks(con, "SELECT i, r, n FROM t ORDER BY id", -1)
  expect_equal(arrow_formats(chunks[[1]]), c(i = "l", r = "g", n = "n"))
  expect_equal(chunks[[1]]$length, 2L)
})

test_that("the first value that is not NULL decides the type", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, a, b, c REAL)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES",
    "(1, NULL, NULL, 1), (2, 2, 2.5, 2), (3, NULL, 3, NULL)"
  ))

  # A REAL column stores its integers as reals
  chunks <- expect_same_chunks(con, "SELECT a, b, c FROM t ORDER BY id", -1)
  expect_equal(arrow_formats(chunks[[1]]), c(a = "l", b = "g", c = "g"))
  expect_equal(arrow_values(chunks[[1]])$b, c(NA, 2.5, 3))
})

test_that("integers widen to double when a real comes later in the chunk", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, x)")
  dbExecute(con, "INSERT INTO t VALUES (1, 1), (2, NULL), (3, 3), (4, 2.5)")
  sql <- "SELECT x FROM t ORDER BY id"

  chunks <- expect_same_chunks(con, sql, -1)
  expect_equal(arrow_formats(chunks[[1]]), c(x = "g"))
  expect_identical(arrow_values(chunks[[1]])$x, c(1, NA, 3, 2.5))

  # Also from beyond 2^53, to the nearest double,
  # where dbFetch() keeps integer64 and truncates the real with a warning
  dbExecute(con, "UPDATE t SET x = 9007199254740993 WHERE id = 3")
  res <- local_result(con, sql)
  chunk <- fetch_arrow_chunk(res)
  expect_equal(arrow_formats(chunk), c(x = "g"))
  expect_identical(arrow_values(chunk)$x, c(1, NA, 2^53, 2.5))
  dbClearResult(res)
  expect_warning(
    expect_equal(
      dbGetQuery(con, sql)$x,
      bit64::as.integer64(c("1", NA, "9007199254740993", "2"))
    ),
    "mixed type"
  )
})

test_that("the first chunk fixes the types for the later chunks", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, x, y, z INTEGER)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, 1, NULL, NULL), (2, 2.75, 2, 2),",
    "(3, -2.75, 3.5, NULL), (4, 1e300, NULL, 4.5), (5, -9e999, NULL, NULL)"
  ))
  res <- local_result(con, "SELECT x, y, z FROM t ORDER BY id")

  first <- fetch_arrow_chunk(res, 1)
  expect_equal(arrow_formats(first), c(x = "l", y = "n", z = "l"))

  # Unlike dbFetch(), which types each fetch anew:
  # a real in an int64 column is truncated toward zero, and NULL beyond the
  # range of int64; a value in a column of the null type is NULL
  rest <- fetch_arrow_chunk(res)
  expect_equal(arrow_formats(rest), c(x = "l", y = "n", z = "l"))
  expect_equal(
    arrow_values(rest, bit64::integer64()),
    data.frame(
      x = bit64::as.integer64(c(2, -2, NA, NA)),
      y = NA,
      z = bit64::as.integer64(c(2, NA, 4, NA))
    )
  )
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 5L)
})

test_that("columns of NULL values take the type of their declared affinity", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, paste(
    "CREATE TABLE t",
    "(i INTEGER, r REAL, n NUMERIC, s TEXT, c CHAR(1), b BLOB, x)"
  ))
  dbExecute(con, "INSERT INTO t (x) VALUES (NULL), (NULL)")

  # Integers through the default path, doubles through Arrow: as values equal
  chunks <- expect_same_chunks(con, "SELECT * FROM t", c(1, 1))
  for (chunk in chunks) {
    expect_equal(
      arrow_formats(chunk),
      c(i = "l", r = "g", n = "g", s = "u", c = "u", b = "z", x = "n")
    )
  }

  # An expression has no declared type
  chunks <- expect_same_chunks(con, "SELECT i + 1 AS e FROM t", -1)
  expect_equal(arrow_formats(chunks[[1]]), c(e = "n"))
})

test_that("64-bit integers keep every digit beyond 2^53", {
  skip_if_not_installed("nanoarrow")
  skip_if_not_installed("bit64")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (id INTEGER, x)")
  dbExecute(con, paste(
    "INSERT INTO t VALUES (1, 9007199254740993), (2, -9223372036854775807),",
    "(3, 9223372036854775807), (4, NULL), (5, 1)"
  ))

  chunks <- expect_same_chunks(
    con,
    "SELECT x FROM t ORDER BY id",
    c(2, -1),
    int64 = bit64::integer64()
  )
  expect_equal(arrow_formats(chunks[[1]]), c(x = "l"))
  expect_equal(
    as.character(arrow_values(chunks[[1]], bit64::integer64())$x),
    c("9007199254740993", "-9223372036854775807")
  )
  expect_equal(
    as.character(arrow_values(chunks[[2]], bit64::integer64())$x),
    c("9223372036854775807", NA, "1")
  )
})

test_that("chunks of 1, k and all rows end where dbFetch() ends", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (x INTEGER)")
  dbExecute(con, "INSERT INTO t VALUES (1), (2), (3), (4), (5)")
  sql <- "SELECT x FROM t ORDER BY x"

  # Each vector gives the chunks of one result, up to one past its end
  for (ns in list(rep(1, 6), c(2, 2, 2), c(5, 1), c(4, 4), c(-1, -1), 6)) {
    expect_same_chunks(con, sql, ns)
  }
})

test_that("a chunk that returns the last row releases the read lock", {
  skip_if_not_installed("nanoarrow")
  path <- withr::local_tempfile(fileext = ".sqlite")
  con <- dbConnect(SQLite(), path)
  on.exit(dbDisconnect(con), add = TRUE)
  dbWriteTable(con, "t", data.frame(a = 1:3))

  res <- dbSendQuery(con, "SELECT a FROM t")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)
  expect_equal(fetch_arrow_chunk(res, 2)$length, 2L)
  expect_false(dbHasCompleted(res))
  expect_equal(fetch_arrow_chunk(res, 1)$length, 1L)
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 3L)

  # The statement is finished and holds no lock on the database
  con2 <- dbConnect(SQLite(), path)
  on.exit(dbDisconnect(con2), add = TRUE)
  sqliteSetBusyHandler(con2, 0L)
  expect_equal(dbExecute(con2, "INSERT INTO t VALUES (4)"), 1L)
})

test_that("an empty result gives a chunk of no rows", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  dbExecute(con, "CREATE TABLE t (i INTEGER, r REAL, x)")

  chunks <- expect_same_chunks(con, "SELECT * FROM t", c(1, -1))
  expect_equal(arrow_formats(chunks[[1]]), c(i = "l", r = "g", x = "n"))
  expect_equal(chunks[[1]]$length, 0L)

  # A statement without columns gives a struct without children
  res <- local_result(con, "CREATE TABLE u (a)")
  chunk <- fetch_arrow_chunk(res)
  expect_equal(chunk$length, 0L)
  expect_length(arrow_formats(chunk), 0L)
  expect_true(dbHasCompleted(res))
})

test_that("a step error after the rows of a chunk comes from the next chunk", {
  skip_if_not_installed("nanoarrow")
  # Row 5 fails, so chunks of 1, 2 or 4 rows end right before it
  sql <- "SELECT id, length(json(v)) AS j FROM t1"
  for (n in c(1L, 2L, 4L)) {
    local({
      con <- local_json_error_at_5()
      expected <- dbGetQuery(con, sql, n = 4)
      res <- local_result(con, sql)

      chunks <- lapply(seq_len(4L / n), function(i) fetch_arrow_chunk(res, n))
      values <- do.call(rbind, lapply(chunks, arrow_values))
      expect_equal(values, expected)
      expect_false(dbHasCompleted(res))
      expect_equal(dbGetRowCount(res), 4L)

      expect_error(fetch_arrow_chunk(res, n), "malformed JSON")
      expect_true(dbHasCompleted(res))
      expect_equal(dbGetRowCount(res), 4L)
      expect_equal(fetch_arrow_chunk(res)$length, 0L)
      expect_equal(dbGetRowCount(res), 4L)
    })
  }
})

test_that("a step error among the rows of a chunk comes from that chunk", {
  skip_if_not_installed("nanoarrow")
  sql <- "SELECT id, length(json(v)) AS j FROM t1"
  local({
    con <- local_json_error_at_5()
    res <- local_result(con, sql)
    expect_equal(arrow_values(fetch_arrow_chunk(res, 3))$id, 1:3)
    expect_error(fetch_arrow_chunk(res, 3), "malformed JSON")
    expect_true(dbHasCompleted(res))
    expect_equal(dbGetRowCount(res), 3L)
  })

  for (n in c(5L, -1L)) {
    local({
      con <- local_json_error_at_5()
      res <- local_result(con, sql)
      expect_error(fetch_arrow_chunk(res, n), "malformed JSON")
      expect_true(dbHasCompleted(res))
      expect_equal(dbGetRowCount(res), 0L)
    })
  }
})

test_that("a handler can't use a result while its Arrow chunk is fetched", {
  skip_if_not_installed("nanoarrow")
  path <- withr::local_tempfile(fileext = ".sqlite")
  con <- dbConnect(SQLite(), path)
  on.exit(dbDisconnect(con), add = TRUE)
  dbExecute(con, "CREATE TABLE t (x INTEGER)")

  con2 <- dbConnect(SQLite(), path)
  on.exit(dbDisconnect(con2), add = TRUE)
  res <- NULL
  messages <- character()
  sqliteSetBusyHandler(con2, function(n) {
    messages <<- c(
      tryCatch(dbClearResult(res), error = conditionMessage),
      tryCatch(fetch_arrow_chunk(res, 1), error = conditionMessage)
    )
    0L
  })

  # The read transaction of `con` holds back the commit of the insert,
  # which the step past the returned row runs, so that it calls the handler
  dbExecute(con, "BEGIN")
  dbGetQuery(con, "SELECT * FROM t")
  res <- dbSendQuery(con2, "INSERT INTO t VALUES (1) RETURNING x")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  expect_equal(arrow_values(fetch_arrow_chunk(res, 1))$x, 1)
  expect_match(messages[[1]], "Can't clear a result while one of its fetches")
  expect_match(messages[[2]], "Can't use a result while one of its fetches")

  # The commit failed, its error is kept for the next fetch
  expect_false(dbHasCompleted(res))
  expect_error(fetch_arrow_chunk(res, 1), "locked")
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 1L)
  dbExecute(con, "COMMIT")
})

test_that("each execution decides its own types", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  res <- local_result(con, "SELECT ? AS x")

  dbBind(res, list(1L))
  expect_equal(arrow_formats(fetch_arrow_chunk(res)), c(x = "l"))
  dbBind(res, list(1.5))
  chunk <- fetch_arrow_chunk(res)
  expect_equal(arrow_formats(chunk), c(x = "g"))
  expect_equal(arrow_values(chunk)$x, 1.5)
})

test_that("an Arrow chunk needs a bound query and a valid number of rows", {
  skip_if_not_installed("nanoarrow")
  con <- local_con()
  res <- local_result(con, "SELECT ? AS x")
  expect_error(fetch_arrow_chunk(res), "needs to be bound")

  dbBind(res, list(1))
  for (n in c(0L, -2L, NA_integer_)) {
    expect_error(fetch_arrow_chunk(res, n), "`n` must be positive, or -1")
  }
  expect_false(dbHasCompleted(res))
  expect_equal(arrow_values(fetch_arrow_chunk(res, 1))$x, 1)
})
