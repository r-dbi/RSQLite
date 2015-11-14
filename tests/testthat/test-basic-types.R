context("Basic types")

basicDf <- data.frame(
  name = c("Alice", "Bob", "Carl", "NA", NA),
  fldInt = as.integer(c(as.integer(1:4), NA)),
  fldDbl = as.double(c(1.1, 2.2, 3.3, 4.4, NA)),
  stringsAsFactors = FALSE
)

test_that("column types as expected in presence of NULLs", {
  db <- dbConnect(SQLite(), ":memory:")
  dbWriteTable(db, "t1", datasets::USArrests)
  
  a1 <- dbGetQuery(db, "SELECT Murder/(Murder - 8.1) FROM t1 LIMIT 10")
  expect_is(a1[[1]], "numeric")

  ## This isn't ideal, but for now, if the first row of a result set
  ## contains a NULL, then that column is forced to be character.
  a2 <- dbGetQuery(db, "SELECT Murder/(Murder - 13.2) FROM t1 LIMIT 10")
  expect_is(a2[[1]], "character")
})

test_that("correct number of columns, even if 0 rows", {
  db <- dbConnect(SQLite(), ":memory:")

  ans <- dbGetQuery(db, "select 1 as a, 2 as b where 1")
  expect_equal(dim(ans), c(1L, 2L))
  
  ans <- dbGetQuery(db, "select 1 as a, 2 as b where 0")
  expect_equal(dim(ans), c(0L, 2L))  
})
