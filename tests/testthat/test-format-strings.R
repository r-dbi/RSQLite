test_that("remaining query text in a warning is not a format string", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  expect_warning(
    expect_equal(dbGetQuery(con, "SELECT 1 AS a; SELECT '%n'")$a, 1),
    "Ignoring remaining part of query: SELECT '%n'",
    fixed = TRUE
  )
  expect_warning(
    expect_equal(dbGetQuery(con, "SELECT 1 AS a; SELECT '%d%d'")$a, 1),
    "Ignoring remaining part of query: SELECT '%d%d'",
    fixed = TRUE
  )
  expect_warning(
    expect_equal(dbGetQuery(con, "SELECT 1 AS a; SELECT '%s%s%s'")$a, 1),
    "Ignoring remaining part of query: SELECT '%s%s%s'",
    fixed = TRUE
  )
})

test_that("SQLite error messages are not format strings", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  expect_error(
    dbGetQuery(con, 'SELECT * FROM "x%n"'),
    "no such table: x%n",
    fixed = TRUE
  )
  expect_error(
    dbGetQuery(con, 'SELECT * FROM "x%d%d%x"'),
    "no such table: x%d%d%x",
    fixed = TRUE
  )
  expect_error(
    dbGetQuery(con, 'SELECT * FROM "x%s%s%s"'),
    "no such table: x%s%s%s",
    fixed = TRUE
  )
})

test_that("table and column names with % in messages", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "t%n%s", data.frame("c%n%s" = 1L, check.names = FALSE))
  expect_equal(
    dbReadTable(con, "t%n%s", check.names = FALSE),
    data.frame("c%n%s" = 1L, check.names = FALSE)
  )

  expect_error(
    dbExecute(con, 'CREATE TABLE "t%n%s" (x)'),
    "table \"t%n%s\" already exists",
    fixed = TRUE
  )
  expect_error(
    dbGetQuery(con, 'SELECT [d%n%s] FROM "t%n%s"'),
    "no such column: d%n%s",
    fixed = TRUE
  )

  expect_warning(
    expect_equal(
      dbGetQuery(con, 'SELECT 30000000000 AS "a%n%s" UNION SELECT 2.5 ORDER BY 1')[[1]],
      c(2.5, 3e10)
    ),
    "Column `a%n%s`: mixed type, first seen values of type real, coercing other values of type integer64",
    fixed = TRUE
  )
})
