context("Basic types")

basicDf <- data.frame(
  name = c("Alice", "Bob", "Carl", "NA", NA),
  fldInt = as.integer(c(as.integer(1:4), NA)),
  fldDbl = as.double(c(1.1, 2.2, 3.3, 4.4, NA)),
  stringsAsFactors = FALSE
)

test_that("correct number of columns, even if 0 rows", {
  db <- dbConnect(SQLite(), ":memory:")

  ans <- dbGetQuery(db, "select 1 as a, 2 as b where 1")
  expect_equal(dim(ans), c(1L, 2L))
  
  ans <- dbGetQuery(db, "select 1 as a, 2 as b where 0")
  expect_equal(dim(ans), c(0L, 2L))  
})
