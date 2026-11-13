# Skips unless a callr session loads the same copy of RSQLite as the tests.
# After `pkgload::load_all()`, a session loads an installed copy, if any,
# which is not the code under test.
skip_unless_callr_loads_tested_rsqlite <- function() {
  tested <- normalizePath(find.package("RSQLite"))
  loaded <- callr::r(function() {
    tryCatch(normalizePath(find.package("RSQLite")), error = function(e) "")
  })
  if (!identical(loaded, tested)) {
    skip(paste0(
      "a callr session loads ",
      if (loaded == "") "no RSQLite" else loaded,
      ", not ",
      tested
    ))
  }
}
