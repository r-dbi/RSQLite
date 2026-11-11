test_that("attempting to change schema with pending rows generates warning", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))

  df <- data.frame(a = letters, b = LETTERS, c = 1:26, stringsAsFactors = FALSE)
  dbWriteTable(con, "t1", df)

  rs <- dbSendQuery(con, "SELECT * FROM t1")
  row1 <- dbFetch(rs, n = 1)
  expect_equal(row1, df[1, ])

  expect_warning(
    rs <- dbSendStatement(con, "CREATE TABLE t2 (x text, y integer)"),
    "pending rows"
  )
  dbClearResult(rs)
})


test_that("simple position binding works", {
  memoise::forget(warning_once)
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "t1", data.frame(x = 1, y = 2))

  expect_warning(
    expect_warning(
      dbGetPreparedQuery(con, "INSERT INTO t1 VALUES (?, ?)",
        bind.data = data.frame(x = 2, y = 1)
      ),
      "deprecated"
    ),
    "`SELECT` queries"
  )

  expect_equal(dbReadTable(con, "t1")$x, c(1, 2))
})

test_that("simple named binding works", {
  `%>%` <- magrittr::`%>%`

  memoise::forget(warning_once)
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "t1", data.frame(x = 1, y = 2))

  dbGetPreparedQuery(con, "INSERT INTO t1 VALUES (:x, :y)",
    bind.data = data.frame(y = 1, x = 2)
  ) %>%
    expect_warning("deprecated") %>%
    expect_warning("`SELECT` queries")

  expect_equal(dbReadTable(con, "t1")$x, c(1, 2))
})

test_that("named binding errors if missing name", {
  `%>%` <- magrittr::`%>%`

  con <- dbConnect(SQLite(), ":memory:")
  dbWriteTable(con, "t1", data.frame(x = 1, y = 2))
  on.exit(dbDisconnect(con), add = TRUE)

  dbGetPreparedQuery(con, "INSERT INTO t1 VALUES (:x, :y)",
    bind.data = data.frame(y = 1)
  ) %>%
    expect_warning("deprecated") %>%
    expect_warning("SQL statements") %>%
    expect_error("No value given for placeholder")
})

test_that("one row per bound select, with factor", {
  memoise::forget(warning_once)
  con <- bind_select_setup()
  on.exit(dbDisconnect(con), add = TRUE)

  id_frame <- data.frame(id = c("e", "a", "c"))

  expect_warning(
    got <- dbGetPreparedQuery(con, "select * from t1 where id = ?", id_frame),
    "deprecated"
  )

  expect_equal(got$id, c("e", "a", "c"))
})

test_that("one row per bound select", {
  memoise::forget(warning_once)
  con <- bind_select_setup()
  on.exit(dbDisconnect(con), add = TRUE)

  id_frame <- data.frame(id = I(c("e", "a", "c")))

  expect_warning(
    got <- dbGetPreparedQuery(con, "select * from t1 where id = ?", id_frame),
    "deprecated"
  )

  expect_equal(got$id, c("e", "a", "c"))
})

test_that("failed matches are silently dropped", {
  con <- bind_select_setup()
  on.exit(dbDisconnect(con), add = TRUE)
  sql <- "SELECT * FROM t1 WHERE id = ?"

  memoise::forget(warning_once)
  expect_warning(
    df1 <- dbGetPreparedQuery(con, sql, data.frame(id = I("X"))),
    "deprecated"
  )
  expect_equal(nrow(df1), 0)
  expect_equal(names(df1), c("id", "x", "y"))

  memoise::forget(warning_once)
  expect_warning(
    df2 <- dbGetPreparedQuery(con, sql, data.frame(id = I(c("X", "Y")))),
    "deprecated"
  )
  expect_equal(nrow(df2), 0)
  expect_equal(names(df2), c("id", "x", "y"))

  memoise::forget(warning_once)
  expect_warning(
    df3 <- dbGetPreparedQuery(con, sql, data.frame(id = I(c("X", "a", "Y")))),
    "deprecated"
  )
  expect_equal(nrow(df3), 1)
  expect_equal(names(df3), c("id", "x", "y"))
})

test_that("NA matches NULL", {
  memoise::forget(warning_once)
  con <- bind_select_setup()
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "INSERT INTO t1 VALUES ('x', NULL, NULL)")

  expect_warning(
    got <- dbGetPreparedQuery(
      con, "SELECT id FROM t1 WHERE y IS :y",
      data.frame(y = NA_integer_)
    ),
    "deprecated"
  )

  expect_equal(got$id, "x")
})

test_that("mark UTF-8 encoding on non-ASCII colnames", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con))
  cn_field <- "\u4e2d\u6587"
  tbl <- data.frame("a")
  colnames(tbl) <- cn_field
  dbWriteTable(con, name = "test", value = tbl)
  got <- dbListFields(con, "test")
  expect_equal(Encoding(got), "UTF-8")
  expect_equal(got, cn_field)
})

test_that("dbFetch with statement other than SELECT warns reasonably (#523)", {
  memoise::forget(warning_once)
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "t1", data.frame(x = 1, y = 2))
  res <- dbSendStatement(con, "INSERT INTO t1 VALUES (2, 1)")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  expect_warning(dbFetch(res), "dbGetRowsAffected")
})

test_that("an error in the middle of a result completes it", {
  con <- json_error_setup()
  on.exit(dbDisconnect(con), add = TRUE)

  res <- dbSendQuery(con, "SELECT id, json(v) AS j FROM t1")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  expect_equal(dbFetch(res, n = 1)$id, 1L)
  expect_error(dbFetch(res), "malformed JSON")
  expect_true(dbHasCompleted(res))
  # The rows read by the failed fetch were not returned, and are lost.
  # They include row 2: the step onto row 3 is one of this fetch's own steps,
  # not one past its last row, so the error comes from this fetch.
  expect_equal(dbGetRowCount(res), 1L)

  # The statement is not restarted from the first row
  out <- dbFetch(res)
  expect_equal(nrow(out), 0L)
  expect_named(out, c("id", "j"))
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 1L)

  # The structure stays available
  out <- dbFetch(res, n = 0)
  expect_equal(nrow(out), 0L)
  expect_named(out, c("id", "j"))
  info <- dbColumnInfo(res)
  expect_equal(info$name, c("id", "j"))
  expect_equal(info$type, c("integer", "character"))
  expect_equal(dbGetRowCount(res), 1L)
})

test_that("an error in a later parameter set completes the result", {
  con <- json_error_setup()
  on.exit(dbDisconnect(con), add = TRUE)

  res <- dbSendQuery(con, "SELECT id, json(v) AS j FROM t1 WHERE id >= ?")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  dbBind(res, list(c(4L, 1L)))
  expect_equal(dbFetch(res, n = 1)$id, 4L)
  expect_error(dbFetch(res), "malformed JSON")
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 1L)
  expect_equal(nrow(dbFetch(res)), 0L)
  expect_equal(dbGetRowCount(res), 1L)

  # A new bind makes the result usable again
  dbBind(res, list(4L))
  expect_false(dbHasCompleted(res))
  expect_equal(dbFetch(res)$id, 4L)
  expect_true(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 1L)
})

test_that("a later parameter set that fails to bind completes the result", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  res <- dbSendQuery(con, "SELECT ? AS x")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  dbBind(res, list(list(as.raw(1), "a")))
  expect_error(dbFetch(res), "raw vectors")
  expect_true(dbHasCompleted(res))
  expect_equal(nrow(dbFetch(res)), 0L)
  expect_equal(dbGetRowCount(res), 0L)
})

test_that("a failed dbBind() asks for a new bind", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  res <- dbSendQuery(con, "SELECT json(?) AS j")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  # The first parameter set fails in the statement
  expect_error(dbBind(res, list(c("oops", "[2]"))), "malformed JSON")
  expect_error(dbFetch(res), "needs to be bound")
  expect_false(dbHasCompleted(res))
  expect_equal(dbGetRowCount(res), 0L)
  expect_equal(dbGetRowsAffected(res), 0L)

  dbBind(res, list(c("[1]", "[2]")))
  expect_equal(dbFetch(res, n = 1)$j, "[1]")

  # The first parameter set fails to bind, after a partial fetch
  expect_error(dbBind(res, list(list("a", as.raw(1)))), "raw vectors")
  expect_error(dbFetch(res), "needs to be bound")
  expect_equal(dbGetRowCount(res), 0L)

  # A new bind makes the result usable again
  dbBind(res, list(c("[3]", "[4]")))
  expect_equal(dbFetch(res)$j, c("[3]", "[4]"))
  expect_true(dbHasCompleted(res))
})

test_that("a statement that fails partway reports the rows it changed", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE u (x INTEGER UNIQUE)")

  res <- dbSendStatement(con, "INSERT INTO u VALUES (?)")
  # The third parameter set fails, after the first two were written
  expect_error(dbBind(res, list(c(1L, 2L, 2L, 3L))), "UNIQUE")
  expect_equal(dbGetRowsAffected(res), 2L)
  expect_error(dbFetch(res), "needs to be bound")

  # A new bind counts its own changes
  dbBind(res, list(3:4))
  expect_equal(dbGetRowsAffected(res), 2L)
  dbClearResult(res)

  expect_error(
    dbExecute(con, "INSERT INTO u VALUES (?)", params = list(c(5L, 4L, 6L))),
    "UNIQUE"
  )
  expect_equal(dbGetQuery(con, "SELECT x FROM u ORDER BY x")$x, 1:5)
})

test_that("rows of a fetch whose conversion fails don't count", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  dbExecute(con, "CREATE TABLE m (x)")
  dbExecute(con, "INSERT INTO m VALUES (1), (2), ('a'), (4), (5)")

  res <- dbSendQuery(con, "SELECT x FROM m")
  on.exit(dbClearResult(res), add = TRUE, after = FALSE)

  expect_equal(dbFetch(res, n = 2)$x, 1:2)
  # The mixed types in the next rows give a warning, made an error here
  withr::with_options(
    list(warn = 2),
    expect_error(dbFetch(res, n = 2), "mixed type")
  )
  expect_equal(dbGetRowCount(res), 2L)

  # The result goes on after the rows of the failed fetch, which are skipped
  expect_false(dbHasCompleted(res))
  expect_equal(dbFetch(res)$x, 5L)
})
