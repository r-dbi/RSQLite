test_that("sqliteHttpVfsCompiled agrees with internal indicator", {
  # The internal helper always exists (registered via cpp11), but be defensive.
  compiled_internal <- FALSE
  if (exists("sqlite_httpvfs_compiled")) {
    expect_no_error({ compiled_internal <- RSQLite:::sqlite_httpvfs_compiled() })
  }
  expect_identical(sqliteHttpVfsCompiled(), isTRUE(compiled_internal))
})
