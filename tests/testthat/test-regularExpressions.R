context("regexp")

test_that("adding support for regular expressions(#296)", {

  con <- dbConnect(
    SQLite())

  on.exit(
    dbDisconnect(con),
    add = TRUE)

  # note true only from first
  # invocation of dbConnect()
  expect_true(
    initRegExp(
      db = con))

  dbWriteTable(
    conn = con,
    name = "iris",
    value = iris)

  # this regular expression is just to
  # try out various syntax elements
  res <- dbGetQuery(
    conn = con,
    statement = 'SELECT "Sepal.Length" FROM iris WHERE Species REGEXP "^v[ei]\\w*[^x-z\\\\s]+$";')

  expect_equal(
    object = nrow(res),
    expected = 100L)

  expect_true(
    object = (6.2 < mean(res$Sepal.Length)) < 6.3)

})

