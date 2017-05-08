context("dbJson")

test_that("JSON types function", {
  con <- dbConnect(SQLite())
  on.exit(dbDisconnect(con), add = TRUE)

  gotJson <- dbGetQuery(con, 'SELECT json(\'{"this":"is","a":["test"]}\')')
  expect_that(gotJson[1,], equals('{"this":"is","a":["test"]}'))

  jsonArray <- dbGetQuery(con, 'SELECT json_array(1,2,3,4)')
  expect_that(jsonArray[1,], equals('[1,2,3,4]'))
})
