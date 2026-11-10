# Collects until a collection frees nothing more: an array that nanoarrow
# built from R vectors goes one level of references per collection, so a test
# with large arrays can leave gigabytes behind for several collections.
# The tests that set RSQLITE_TEST_LARGE_ARROW call it before and after they
# allocate, so that their peaks do not add up.
gc_until_stable <- function() {
  used <- NULL
  for (i in 1:20) {
    now <- gc()[, 1]
    if (identical(now, used)) {
      break
    }
    used <- now
  }
  invisible()
}
