test_that("autocommit", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit(
    {
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  dbWriteTable(con, "a", data.frame(a = 1))
  expect_equal(dbListTables(con2), "a")
})

test_that("commit unnamed transactions", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit(
    {
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  expect_false(sqliteIsTransacting(con))
  dbBegin(con)
  dbWriteTable(con, "a", data.frame(a = 1))
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())
  dbCommit(con)
  expect_false(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), "a")

  dbWriteTable(con, "b", data.frame(a = 1))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), c("a", "b"))
})

test_that("rollback unnamed transactions", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit(
    {
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  expect_false(sqliteIsTransacting(con))
  dbBegin(con)
  dbWriteTable(con, "a", data.frame(a = 1))
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())
  dbRollback(con)
  expect_false(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), character())
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "b", data.frame(a = 1))
  expect_equal(dbListTables(con), "b")
  expect_equal(dbListTables(con2), "b")
})

test_that("no nested unnamed transactions (commit after error)", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit(
    {
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )
  expect_false(sqliteIsTransacting(con))
  dbBegin(con)
  expect_true(sqliteIsTransacting(con))
  expect_error(dbBegin(con))
  expect_true(sqliteIsTransacting(con))
  dbCommit(con)
  expect_false(sqliteIsTransacting(con))

  dbWriteTable(con, "a", data.frame(a = 1))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), "a")
})

test_that("no nested unnamed transactions (rollback after error)", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit(
    {
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  expect_false(sqliteIsTransacting(con))
  dbBegin(con)
  expect_true(sqliteIsTransacting(con))
  expect_error(dbBegin(con))
  expect_true(sqliteIsTransacting(con))
  dbRollback(con)
  expect_false(sqliteIsTransacting(con))

  dbWriteTable(con, "a", data.frame(a = 1))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), "a")
})

test_that("commit named transactions", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit(
    {
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  expect_false(sqliteIsTransacting(con))
  dbBegin(con, name = "tx")
  dbWriteTable(con, "a", data.frame(a = 1))
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())
  dbCommit(con, name = "tx")
  expect_false(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), "a")

  dbWriteTable(con, "b", data.frame(a = 1))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), c("a", "b"))
})

test_that("rollback named transactions", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit(
    {
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  expect_false(sqliteIsTransacting(con))
  dbBegin(con, name = "tx")
  dbWriteTable(con, "a", data.frame(a = 1))
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbRollback(con, name = "tx")
  expect_false(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), character())
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "b", data.frame(a = 1))
  expect_equal(dbListTables(con), "b")
  expect_equal(dbListTables(con2), "b")
})

test_that("nested named transactions (commit - commit)", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit(
    {
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  expect_false(sqliteIsTransacting(con))
  dbBegin(con, name = "tx")
  dbWriteTable(con, "a", data.frame(a = 1))
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbBegin(con, name = "tx2")
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "b", data.frame(a = 1))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), character())

  dbCommit(con, name = "tx2")
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), character())

  dbCommit(con, name = "tx")
  expect_false(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), c("a", "b"))

  dbWriteTable(con, "c", data.frame(a = 1))
  expect_equal(dbListTables(con), c("a", "b", "c"))
  expect_equal(dbListTables(con2), c("a", "b", "c"))
})

test_that("nested named transactions (commit - rollback)", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit(
    {
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  expect_false(sqliteIsTransacting(con))
  dbBegin(con, name = "tx")
  dbWriteTable(con, "a", data.frame(a = 1))
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbBegin(con, name = "tx2")
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "b", data.frame(a = 1))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), character())

  dbCommit(con, name = "tx2")
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), character())

  dbRollback(con, name = "tx")
  expect_false(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), character())
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "c", data.frame(a = 1))
  expect_equal(dbListTables(con), "c")
  expect_equal(dbListTables(con2), "c")
})

test_that("nested named transactions (rollback - commit)", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit(
    {
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  expect_false(sqliteIsTransacting(con))
  dbBegin(con, name = "tx")
  dbWriteTable(con, "a", data.frame(a = 1))
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbBegin(con, name = "tx2")
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "b", data.frame(a = 1))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), character())

  dbRollback(con, name = "tx2")
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbCommit(con, name = "tx")
  expect_false(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), "a")

  dbWriteTable(con, "c", data.frame(a = 1))
  expect_equal(dbListTables(con), c("a", "c"))
  expect_equal(dbListTables(con2), c("a", "c"))
})

test_that("nested named transactions (rollback - rollback)", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit(
    {
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  expect_false(sqliteIsTransacting(con))
  dbBegin(con, name = "tx")
  dbWriteTable(con, "a", data.frame(a = 1))
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbBegin(con, name = "tx2")
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "b", data.frame(a = 1))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), character())

  dbRollback(con, name = "tx2")
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbRollback(con, name = "tx")
  expect_false(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), character())
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "c", data.frame(a = 1))
  expect_equal(dbListTables(con), "c")
  expect_equal(dbListTables(con2), "c")
})

test_that("named transactions with keywords", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit(
    {
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  expect_false(sqliteIsTransacting(con))
  dbBegin(con, name = "SELECT")
  dbWriteTable(con, "a", data.frame(a = 1))
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())
  dbCommit(con, name = "SELECT")
  expect_false(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), "a")

  dbBegin(con, name = "WHERE")
  dbWriteTable(con, "b", data.frame(b = 1))
  expect_true(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), "a")
  dbRollback(con, name = "WHERE")
  expect_false(sqliteIsTransacting(con))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), "a")
})

test_that("transactions managed without dbBegin+dbCommit", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  on.exit(dbDisconnect(con))

  expect_false(sqliteIsTransacting(con))
  dbExecute(con, "BEGIN")
  expect_true(sqliteIsTransacting(con))
  dbWriteTable(con, "a", data.frame(a = 1))
  expect_true(sqliteIsTransacting(con))
  dbExecute(con, "END")
  expect_false(sqliteIsTransacting(con))

  dbExecute(con, "BEGIN")
  expect_true(sqliteIsTransacting(con))
  dbWriteTable(con, "b", data.frame(b = 1))
  expect_true(sqliteIsTransacting(con))
  dbExecute(con, "COMMIT")
  expect_false(sqliteIsTransacting(con))

  expect_false(sqliteIsTransacting(con))
  dbExecute(con, "BEGIN IMMEDIATE")
  expect_true(sqliteIsTransacting(con))
  dbWriteTable(con, "c", data.frame(c = 1))
  expect_true(sqliteIsTransacting(con))
  dbExecute(con, "END")
  expect_false(sqliteIsTransacting(con))

  dbExecute(con, "BEGIN IMMEDIATE")
  expect_true(sqliteIsTransacting(con))
  dbWriteTable(con, "d", data.frame(d = 1))
  expect_true(sqliteIsTransacting(con))
  dbExecute(con, "COMMIT")
  expect_false(sqliteIsTransacting(con))
})

test_that("transactions managed without dbBegin+dbRollback", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  on.exit(dbDisconnect(con))

  expect_false(sqliteIsTransacting(con))
  dbExecute(con, "BEGIN")
  expect_true(sqliteIsTransacting(con))
  dbWriteTable(con, "a", data.frame(a = 1))
  expect_true(sqliteIsTransacting(con))
  dbExecute(con, "ROLLBACK")
  expect_false(sqliteIsTransacting(con))

  dbExecute(con, "BEGIN IMMEDIATE")
  expect_true(sqliteIsTransacting(con))
  dbWriteTable(con, "b", data.frame(b = 1))
  expect_true(sqliteIsTransacting(con))
  dbExecute(con, "ROLLBACK")
  expect_false(sqliteIsTransacting(con))
})

test_that("mixed management of transactions", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  on.exit(dbDisconnect(con))

  expect_false(sqliteIsTransacting(con))
  dbExecute(con, "BEGIN")
  expect_true(sqliteIsTransacting(con))
  dbWriteTable(con, "a", data.frame(a = 1))
  expect_true(sqliteIsTransacting(con))
  dbCommit(con)
  expect_false(sqliteIsTransacting(con))

  dbExecute(con, "BEGIN IMMEDIATE")
  expect_true(sqliteIsTransacting(con))
  dbWriteTable(con, "b", data.frame(b = 1))
  expect_true(sqliteIsTransacting(con))
  dbCommit(con)
  expect_false(sqliteIsTransacting(con))

  expect_false(sqliteIsTransacting(con))
  dbExecute(con, "BEGIN")
  expect_true(sqliteIsTransacting(con))
  dbWriteTable(con, "c", data.frame(c = 1))
  expect_true(sqliteIsTransacting(con))
  dbRollback(con)
  expect_false(sqliteIsTransacting(con))

  dbExecute(con, "BEGIN IMMEDIATE")
  expect_true(sqliteIsTransacting(con))
  dbWriteTable(con, "d", data.frame(d = 1))
  expect_true(sqliteIsTransacting(con))
  dbRollback(con)
  expect_false(sqliteIsTransacting(con))

  dbBegin(con)
  expect_true(sqliteIsTransacting(con))
  dbWriteTable(con, "e", data.frame(e = 1))
  expect_true(sqliteIsTransacting(con))
  dbExecute(con, "COMMIT")
  expect_false(sqliteIsTransacting(con))

  dbBegin(con)
  expect_true(sqliteIsTransacting(con))
  dbWriteTable(con, "f", data.frame(f = 1))
  expect_true(sqliteIsTransacting(con))
  dbExecute(con, "END")
  expect_false(sqliteIsTransacting(con))

  dbBegin(con)
  expect_true(sqliteIsTransacting(con))
  dbWriteTable(con, "g", data.frame(g = 1))
  expect_true(sqliteIsTransacting(con))
  dbExecute(con, "ROLLBACK")
  expect_false(sqliteIsTransacting(con))
})
