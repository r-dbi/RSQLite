test_that("percentile extension", {
  con <- dbConnect(SQLite(), ":memory:")
  on.exit(dbDisconnect(con), add = TRUE)

  dbWriteTable(con, "tbl", data.frame(x = 1:9))

  ans1 <- dbGetQuery(con, "SELECT median(x) FROM tbl")
  expect_equal(ans1[[1]], 5)

  ans2 <- dbGetQuery(con, "SELECT percentile(x, 50) FROM tbl")
  expect_equal(ans2[[1]], 5)

  ans3 <- dbGetQuery(con, "SELECT percentile_cont(x, 0.5) FROM tbl")
  expect_equal(ans3[[1]], 5)

  ans4 <- dbGetQuery(con, "SELECT percentile_disc(x, 0.5) FROM tbl")
  expect_equal(ans4[[1]], 5)
})
