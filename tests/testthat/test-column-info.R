context("column-info")

test_that("can extract column info", {
  db <- memory_db()
  on.exit(dbDisconnect(db))

  df <- data.frame(
    a = 1L, b = 2, c = "three", d = I(list(raw(4))),
    stringsAsFactors = FALSE
  )
  dbWriteTable(db, "test", df)

  res <- dbSendQuery(db, "SELECT * FROM test")
  info <- dbColumnInfo(res)
  dbClearResult(res)

  expect_equal(
    info,
    data.frame(
      name = names(df),
      type = vapply(df, typeof, character(1)),
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  )
})
