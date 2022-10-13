# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

test_that("simultaneous_connections", {
  cons <- list()
  on.exit(try_silent(lapply(cons, dbDisconnect)), add = TRUE)
  for (i in seq_len(50L)) {
    cons <- c(cons, connect(ctx))
  }
  inherit_from_connection <- vapply(cons, is, class2 = "DBIConnection", logical(1))
  expect_true(all(inherit_from_connection))
})

test_that("stress_connections", {
  for (i in seq_len(50L)) {
    con <- connect(ctx)
    expect_s4_class(con, "DBIConnection")
    expect_error(dbDisconnect(con), NA)
  }
})
