context("blob")

test_that("adding large blob to table survives valgrind check (#192)", {
  # Requires 64-bit system
  skip_on_appveyor()

  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  data <- data.frame(id = 1, data = I(list(raw(1e8))))
  data$data <- unclass(data$data)
  dbWriteTable(con, "data", data)
  expect_equal(
    dbReadTable(con, "data"),
    data
  )
})
