context("transactions")

test_that("autocommit", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit({dbDisconnect(con); dbDisconnect(con2)}, add = TRUE)

  dbWriteTable(con, "a", data.frame(a=1))
  expect_equal(dbListTables(con2), "a")
})

test_that("commit unnamed transactions", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit({dbDisconnect(con); dbDisconnect(con2)}, add = TRUE)

  dbBegin(con)
  dbWriteTable(con, "a", data.frame(a=1))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())
  dbCommit(con)
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), "a")

  dbWriteTable(con, "b", data.frame(a=1))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), c("a", "b"))
})

test_that("rollback unnamed transactions", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit({dbDisconnect(con); dbDisconnect(con2)}, add = TRUE)

  dbBegin(con)
  dbWriteTable(con, "a", data.frame(a=1))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())
  dbRollback(con)
  expect_equal(dbListTables(con), character())
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "b", data.frame(a=1))
  expect_equal(dbListTables(con), "b")
  expect_equal(dbListTables(con2), "b")
})

test_that("no nested unnamed transactions (commit after error)", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit({dbDisconnect(con); dbDisconnect(con2)}, add = TRUE)

  dbBegin(con)
  expect_error(dbBegin(con))
  dbCommit(con)

  dbWriteTable(con, "a", data.frame(a=1))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), "a")
})

test_that("no nested unnamed transactions (rollback after error)", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit({dbDisconnect(con); dbDisconnect(con2)}, add = TRUE)

  dbBegin(con)
  expect_error(dbBegin(con))
  dbCommit(con)

  dbWriteTable(con, "a", data.frame(a=1))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), "a")
})

test_that("commit named transactions", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit({dbDisconnect(con); dbDisconnect(con2)}, add = TRUE)

  dbBegin(con, name = "tx")
  dbWriteTable(con, "a", data.frame(a=1))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())
  dbCommit(con, name = "tx")
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), "a")

  dbWriteTable(con, "b", data.frame(a=1))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), c("a", "b"))
})

test_that("rollback named transactions", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit({dbDisconnect(con); dbDisconnect(con2)}, add = TRUE)

  dbBegin(con, name = "tx")
  dbWriteTable(con, "a", data.frame(a=1))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbRollback(con, name = "tx")
  expect_equal(dbListTables(con), character())
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "b", data.frame(a=1))
  expect_equal(dbListTables(con), "b")
  expect_equal(dbListTables(con2), "b")
})

test_that("nested named transactions (commit - commit)", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit({dbDisconnect(con); dbDisconnect(con2)}, add = TRUE)

  dbBegin(con, name = "tx")
  dbWriteTable(con, "a", data.frame(a=1))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbBegin(con, name = "tx2")
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "b", data.frame(a=1))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), character())

  dbCommit(con, name = "tx2")
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), character())

  dbCommit(con, name = "tx")
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), c("a", "b"))

  dbWriteTable(con, "c", data.frame(a=1))
  expect_equal(dbListTables(con), c("a", "b", "c"))
  expect_equal(dbListTables(con2), c("a", "b", "c"))
})

test_that("nested named transactions (commit - rollback)", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit({dbDisconnect(con); dbDisconnect(con2)}, add = TRUE)

  dbBegin(con, name = "tx")
  dbWriteTable(con, "a", data.frame(a=1))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbBegin(con, name = "tx2")
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "b", data.frame(a=1))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), character())

  dbCommit(con, name = "tx2")
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), character())

  dbRollback(con, name = "tx")
  expect_equal(dbListTables(con), character())
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "c", data.frame(a=1))
  expect_equal(dbListTables(con), "c")
  expect_equal(dbListTables(con2), "c")
})

test_that("nested named transactions (rollback - commit)", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit({dbDisconnect(con); dbDisconnect(con2)}, add = TRUE)

  dbBegin(con, name = "tx")
  dbWriteTable(con, "a", data.frame(a=1))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbBegin(con, name = "tx2")
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "b", data.frame(a=1))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), character())

  dbRollback(con, name = "tx2")
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbCommit(con, name = "tx")
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), "a")

  dbWriteTable(con, "c", data.frame(a=1))
  expect_equal(dbListTables(con), c("a", "c"))
  expect_equal(dbListTables(con2), c("a", "c"))
})

test_that("nested named transactions (rollback - rollback)", {
  db_file <- tempfile("transactions", fileext = ".sqlite")
  con <- dbConnect(SQLite(), db_file)
  con2 <- dbConnect(SQLite(), db_file)
  on.exit({dbDisconnect(con); dbDisconnect(con2)}, add = TRUE)

  dbBegin(con, name = "tx")
  dbWriteTable(con, "a", data.frame(a=1))
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbBegin(con, name = "tx2")
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "b", data.frame(a=1))
  expect_equal(dbListTables(con), c("a", "b"))
  expect_equal(dbListTables(con2), character())

  dbRollback(con, name = "tx2")
  expect_equal(dbListTables(con), "a")
  expect_equal(dbListTables(con2), character())

  dbRollback(con, name = "tx")
  expect_equal(dbListTables(con), character())
  expect_equal(dbListTables(con2), character())

  dbWriteTable(con, "c", data.frame(a=1))
  expect_equal(dbListTables(con), "c")
  expect_equal(dbListTables(con2), "c")
})
