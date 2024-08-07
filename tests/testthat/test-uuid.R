test_that("adding support for uuid functions", {
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
      extension = "uuid")
  )

  res1 <- dbGetQuery(
    conn = con,
    statement = 'SELECT uuid();'
  )

  expect_true(
    object = nchar(res1[[1]][1]) == 36L
  )

  res2 <- dbGetQuery(
    conn = con,
    statement = 'SELECT uuid();'
  )

  expect_true(
    object = !identical(res1[[1]][1], res2[[1]][1])
  )

})
