# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

test_that("send_query_stale_warning", {
  con <- connect(ctx)
  on.exit(dbDisconnect(con))
  expect_warning(dbSendQuery(con, trivial_query()), NA)
  expect_warning({
    dbDisconnect(con)
    gc()
  })
  on.exit(NULL)
})

test_that("send_statement_stale_warning", {
  con <- connect(ctx)
  on.exit(dbDisconnect(con))
  expect_warning(dbSendStatement(con, trivial_query()), NA)
  expect_warning({
    dbDisconnect(con)
    gc()
  })
  on.exit(NULL)
})
