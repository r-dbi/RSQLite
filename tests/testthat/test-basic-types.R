context("Basic types")

basicDf <- data.frame(
  name = c("Alice", "Bob", "Carl", "NA", NA),
  fldInt = as.integer(c(as.integer(1:4), NA)),
  fldDbl = as.double(c(1.1, 2.2, 3.3, 4.4, NA)),
  stringsAsFactors = FALSE
)

test_that("round-trip leaves data.frame unchanged", {
  db <- memory_db()
  on.exit(dbDisconnect(db), add = TRUE)

  dbWriteTable(db, "t1", basicDf, row.names = FALSE)

  expect_equal(dbGetQuery(db, "select * from t1"), basicDf)
  expect_equal(dbReadTable(db, "t1"), basicDf)
})

test_that("NAs work in first row", {
  db <- memory_db()
  on.exit(dbDisconnect(db), add = TRUE)

  na_first <- basicDf[c(5, 1:4), ]
  rownames(na_first) <- NULL
  dbWriteTable(db, "t1", na_first, row.names = FALSE)

  expect_equal(dbReadTable(db, "t1"), na_first)
})

test_that("row-by-row fetch is equivalent", {
  db <- memory_db()
  on.exit(dbDisconnect(db), add = TRUE)

  dbWriteTable(db, "t1", basicDf, row.names = FALSE)

  rs <- dbSendQuery(db, "SELECT * FROM t1")
  on.exit({dbClearResult(rs); dbDisconnect(db)}, add = FALSE)
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
  on.exit(dbDisconnect(db), add = TRUE)

  dbWriteTable(db, "t1", datasets::USArrests)

  a1 <- dbGetQuery(db, "SELECT Murder/(Murder - 8.1) FROM t1 LIMIT 10")
  expect_is(a1[[1]], "numeric")

  # Type inference now works properly in presence of NULL values (#74)
  a2 <- dbGetQuery(db, "SELECT Murder/(Murder - 13.2) FROM t1 LIMIT 10")
  expect_is(a2[[1]], "numeric")
})

test_that("correct number of columns, even if 0 rows", {
  db <- memory_db()
  on.exit(dbDisconnect(db), add = TRUE)

  ans <- dbGetQuery(db, "select 1 as a, 2 as b where 1")
  expect_equal(dim(ans), c(1L, 2L))

  ans <- dbGetQuery(db, "select 1 as a, 2 as b where 0")
  expect_equal(dim(ans), c(0L, 2L))
})

test_that("BLOBs retrieve as blob objects", {
  con <- memory_db()
  on.exit(dbDisconnect(con), add = TRUE)

  local <- data.frame(
    a = 1:10,
    z = I(lapply(paste("hello", 1:10), charToRaw))
  )
  dbWriteTable(con, "t1", local)

  remote <- dbReadTable(con, "t1")
  expect_equal(remote$z, blob::as.blob(unclass(local$z)))
})

test_that("integers are upscaled to reals", {
  con <- memory_db()
  on.exit(dbDisconnect(con))

  expect_equal(
    dbGetQuery(con, "SELECT 1 AS a UNION SELECT 2.5 ORDER BY a")$a,
    c(1, 2.5)
  )
  expect_equal(
    dbGetQuery(con, "SELECT 3 AS a UNION SELECT 2.5 ORDER BY a")$a,
    c(2.5, 3)
  )
})

test_that("warnings on mixed data types (#161)", {
  con <- memory_db()
  on.exit(dbDisconnect(con))

  expect_warning(
    expect_equal(
      dbGetQuery(con, "SELECT 30000000000 AS a UNION SELECT 2.5 ORDER BY a")$a,
      c(2.5, 3e10)
    ),
    "Column `a`: mixed type, first seen values of type real, coercing other values of type integer64",
    fixed = TRUE
  )

  expect_warning(
    expect_equal(
      dbGetQuery(con, "SELECT 10000000000 AS a UNION SELECT 2.5e10 ORDER BY a")$a,
      bit64::as.integer64(c(1e10, 2.5e10))
    ),
    "Column `a`: mixed type, first seen values of type integer64, coercing other values of type real",
    fixed = TRUE
  )

  expect_warning(
    expect_equal(
      dbGetQuery(con, "SELECT 'a' AS a, 1 as id UNION SELECT 2, 2 UNION SELECT 2.5, 3 ORDER BY id")$a,
      c("a", "2", "2.5")
    ),
    "Column `a`: mixed type, first seen values of type string, coercing other values of type integer, real",
    fixed = TRUE
  )
})
