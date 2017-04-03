context("sd")

test_that("sd for multiple and single values", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con))
  initExtension(con)

  res <- dbGetQuery(
    con,
    "SELECT stdev(a) FROM (SELECT 1 AS a UNION ALL SELECT 2 UNION ALL SELECT 3)"
  )
  expect_equal(res[[1]], sd(1:3))

  res <- dbGetQuery(
    con,
    "SELECT stdev(a) FROM (SELECT 1 AS a)"
  )
  expect_true(is.na(res[[1]]))

  res <- dbGetQuery(
    con,
    "SELECT variance(a) FROM (SELECT 1 AS a)"
  )
  expect_true(is.na(res[[1]]))
})
