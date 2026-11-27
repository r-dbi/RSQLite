# This file is part of the standard setup for testthat.
# It is recommended that you do not modify it.
#
# Where should you do additional test configuration?
# Learn more about the roles of various files in:
# * https://r-pkgs.org/tests.html
# * https://testthat.r-lib.org/reference/test_package.html#special-files

library(testthat)
library(RSQLite)

res <- test_check("RSQLite")

# testthat counts a test as erroring only if its last result is an error.
# A warning from an exit handler (on.exit(), withr::defer()) that runs after
# the error is recorded last and hides it, so test_check() does not stop.
# Fail the check if any result of any test is an error.
errored <- vapply(
  res,
  function(x) any(vapply(x$results, inherits, logical(1), "expectation_error")),
  logical(1)
)
if (any(errored)) {
  tests <- vapply(res[errored], function(x) paste0(x$file, ": ", x$test), "")
  stop(
    "Test errors hidden by later results:\n",
    paste0("* ", tests, collapse = "\n"),
    call. = FALSE
  )
}
