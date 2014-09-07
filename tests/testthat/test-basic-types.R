context("Basic types")

memory_db <- function() {
  dbConnect(SQLite(), ":memory:")
}

basicDf <- data.frame(
  name = c("Alice", "Bob", "Carl", "NA", NA),
  fldInt = as.integer(c(as.integer(1:4), NA)),
  fldDbl = as.double(c(1.1, 2.2, 3.3, 4.4, NA)),
  stringsAsFactors = FALSE
)

test_that("round-trip leaves data.frame unchanged", {
  db <- memory_db()
  dbWriteTable(db, "t1", basicDf, row.names = FALSE)

  expect_equal(dbGetQuery(db, "select * from t1"), basicDf)
  expect_equal(dbReadTable(db, "t1"), basicDf)
})

test_that("NAs work in first row", {
  db <- memory_db()

  na_first <- basicDf[c(5, 1:4), ]
  rownames(na_first) <- NULL
  dbWriteTable(db, "t1", na_first, row.names = FALSE)
  
  expect_equal(dbReadTable(db, "t1"), na_first)
})

test_that("row-by-row fetch is equivalent", {
  db <- memory_db()
  dbWriteTable(db, "t1", basicDf, row.names = FALSE)
  
  rs <- dbSendQuery(db, "SELECT * FROM t1")
  on.exit(dbClearResult(rs))
  for (i in 1:5) {
    row <- dbFetch(rs, 1L)
    expect_equal(row, basicDf[i, ], check.attributes = FALSE)
  }
  
  row <- dbFetch(rs, 1L)
  expect_equal(nrow(row), 0L)
  
  expect_true(dbHasCompleted(rs))
})

test_that("column types as expected in presence of NULLs", {
  db <- memory_db()
  dbWriteTable(db, "t1", datasets::USArrests)
  
  a1 <- dbGetQuery(db, "SELECT Murder/(Murder - 8.1) FROM t1 LIMIT 10")
  expect_is(a1[[1]], "numeric")

  ## This isn't ideal, but for now, if the first row of a result set
  ## contains a NULL, then that column is forced to be character.
  a2 <- dbGetQuery(db, "SELECT Murder/(Murder - 13.2) FROM t1 LIMIT 10")
  expect_is(a2[[1]], "character")
})

test_that("correct number of columns, even if 0 rows", {
  db <- memory_db()

  ans <- dbGetQuery(db, "select 1 as a, 2 as b where 1")
  expect_equal(dim(ans), c(1L, 2L))
  
  ans <- dbGetQuery(db, "select 1 as a, 2 as b where 0")
  expect_equal(dim(ans), c(0L, 2L))  
})

test_that("BLOBs retrieve as raw vectors", {
  con <- dbConnect(SQLite(), ":memory:")
  local <- data.frame(
    a = 1:10,
    z = I(lapply(paste("hello", 1:10), charToRaw))
  )
  dbWriteTable(con, "t1", local)
  
  remote <- dbReadTable(con, "t1")
  expect_equal(remote$z, unclass(local$z))
})
