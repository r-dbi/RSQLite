context("astyle")

test_that("source code formatting", {
  expect_warning(astyle("--dry-run"), NA)
})
