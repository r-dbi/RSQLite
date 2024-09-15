test_that("adding support for lines function", {
  con <- dbConnect(
    SQLite()
  )

  on.exit(
    dbDisconnect(con),
    add = TRUE
  )

  expect_true(
    initExtension(
      db = con,
      extension = "lines")
  )

  tf <- tempfile()
  reps <- 100
  for (i in seq_len(reps)) {
    cat(
      paste0(sample(c(LETTERS, letters), reps, replace = TRUE), collapse = ""),
      file = tf,
      sep = "\n",
      append = TRUE
    )}

  res1 <- dbGetQuery(
    conn = con,
    statement = paste0(
      "SELECT * from lines_read('", tf, "');"
    )
  )

  expect_true(
    object = all(nchar(res1$line) == reps)
  )

  expect_true(
    object = nrow(res1) == reps
  )

  expect_true(
    object = res1$line[1] != res1$line[reps]
  )

  res2 <- dbGetQuery(
    conn = con,
    statement = 'SELECT lines_version();'
  )

  expect_true(
    object = compareVersion(res2$`lines_version()`, "0.2.2") >= 0L
  )

})
