# Created by DBItest::use_dbitest(), do not edit by hand

ctx <- get_default_context()

test_that("package_dependencies", {
  pkg_path <- get_pkg_path(ctx)
  pkg_deps_df <- `::`(desc, desc_get_deps)(pkg_path)
  pkg_imports <- pkg_deps_df[pkg_deps_df[["type"]] == "Imports", ][["package"]]
  expect_true("DBI" %in% pkg_imports)
  expect_true("methods" %in% pkg_imports)
})

test_that("package_name", {
  pkg_name <- package_name(ctx)
  expect_match(pkg_name, "^R")
})
