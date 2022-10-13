# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

test_that("can_disconnect", {
  con <- connect(ctx)
  expect_invisible_true(dbDisconnect(con))
})
