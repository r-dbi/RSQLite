context("dbSendQuery")

test_that("bound params must match query params", {
  con <- datasetsDb()
  rs <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = $x")
  
  expect_error(dbBind(rs, list()), "1 params; 0 supplied") 
  expect_error(dbBind(rs, list(y = 1)), "No parameter")
  expect_error(dbBind(rs, list(quote(a))), "type symbol")
})
