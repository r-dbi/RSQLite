context("regexp")

test_that("adding support for regular expressions (#296)", {

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
  # try out various syntax elements,
  # selecting versicolor and virginica
  res <- dbGetQuery(
    conn = con,
    statement = 'SELECT "Sepal.Length" FROM iris WHERE Species REGEXP "^v[ei]\\w*[^x-z\\\\s]+$";')

  expect_equal(
    object = nrow(res),
    expected = 100L)

  expect_true(
    object = (6.2 < mean(res$Sepal.Length)) < 6.3)

  # REGEXP also works with numerical columns
  res <- dbGetQuery(
    conn = con,
    statement = 'SELECT Species FROM iris WHERE "Sepal.Width" REGEXP "3[.][4-6]";')

  # frequencies of Species
  res <- table(sort(res$Species))
  expect_setequal(res, c(18L, 1L, 3L))

  # work with strings in dataset
  dbWriteTable(
    conn = con,
    name = "mtcars",
    value = mtcars,
    row.names = TRUE)

  # another REGEXP example as we
  # are not interested in E types
  res <- dbGetQuery(
    conn = con,
    statement = 'SELECT * FROM mtcars WHERE row_names REGEXP "Merc.*S[^E].*";')

  # expected output
  expect_setequal(res$row_names, c("Merc 450SL", "Merc 450SLC"))

})


test_that("regular expressions can be initialized twice without harm", {

  con <- dbConnect(SQLite())

  expect_true(initRegExp(db = con))
  expect_true(initRegExp(db = con))

})

