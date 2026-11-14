# Starts an R session for a test that runs the package in another process,
# and closes it when `.local_envir` exits.
# The session loads the installed package, so the test skips
# when that is not the copy under test, as under devtools::test().
local_rsqlite_session <- function(.local_envir = parent.frame()) {
  skip_if_not_installed("callr")

  session <- callr::r_session$new()
  withr::defer(session$close(), envir = .local_envir)

  path <- session$run(function() {
    tryCatch(
      getNamespaceInfo(loadNamespace("RSQLite"), "path"),
      error = function(e) NA_character_
    )
  })
  ours <- getNamespaceInfo(asNamespace("RSQLite"), "path")
  same <- !is.na(path) &&
    identical(
      normalizePath(path, winslash = "/", mustWork = FALSE),
      normalizePath(ours, winslash = "/", mustWork = FALSE)
    )
  if (!same) {
    skip("Needs the package under test installed, for a separate R session")
  }

  session
}
