test_that("JSON types function", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  gotJson <- dbGetQuery(con, 'SELECT json(\'{"this":"is","a":["test"]}\')')
  expect_equal(gotJson[1, ], '{"this":"is","a":["test"]}')

  jsonArray <- dbGetQuery(con, "SELECT json_array(1,2,3,4)")
  expect_equal(jsonArray[1, ], "[1,2,3,4]")
})
