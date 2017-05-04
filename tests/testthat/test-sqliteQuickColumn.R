context("sqliteQuickColumn")

set.seed(0x977)

test_that("sqliteQuickColumn round trips cleanly", {
  mk_blob <- function(n) as.raw(sample(0:255, n, replace = TRUE))

  df <- data.frame(
    a = letters[1:10],
    b = rnorm(10),
    c = sample(1:10),
    d = blob::as.blob(lapply(1:10, function(x) mk_blob(sample(10:256, 1)))),
    stringsAsFactors = FALSE
  )

  db <- dbConnect(SQLite(), dbname = ":memory:")
  on.exit(dbDisconnect(db), add = TRUE)

  dbWriteTable(db, "t", df)

  expect_equal(sqliteQuickColumn(db, "t", "a"), df$a)
  expect_equal(sqliteQuickColumn(db, "t", "b"), df$b)
  expect_equal(sqliteQuickColumn(db, "t", "c"), df$c)
  expect_equal(sqliteQuickColumn(db, "t", "d"), df$d)
})
