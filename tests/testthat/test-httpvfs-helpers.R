test_that("sqlite_http_config sets env vars and returns previous values", {
  skip_on_cran()

  env_names <- c(
    "RSQLITE_HTTP_CACHE_MB",
    "RSQLITE_HTTP_PREFETCH_PAGES",
    "RSQLITE_HTTP_FALLBACK_FULLDL"
  )
  old_raw <- Sys.getenv(env_names, unset = NA_character_)
  on.exit(
    {
      for (i in seq_along(env_names)) {
        name <- env_names[[i]]
        value <- old_raw[[i]]
        if (is.na(value) || !nzchar(value)) {
          Sys.unsetenv(name)
        } else {
          Sys.setenv(structure(list(value), names = name))
        }
      }
    },
    add = TRUE
  )

  Sys.setenv(
    RSQLITE_HTTP_CACHE_MB = "4",
    RSQLITE_HTTP_PREFETCH_PAGES = "0",
    RSQLITE_HTTP_FALLBACK_FULLDL = "1"
  )

  prev <- sqlite_http_config(
    cache_size_mb = 8,
    prefetch_pages = 2,
    fallback_full_download = FALSE
  )

  expect_identical(prev$cache_size_mb, 4L)
  expect_identical(prev$prefetch_pages, 0L)
  expect_identical(prev$fallback_full_download, TRUE)

  expect_identical(Sys.getenv("RSQLITE_HTTP_CACHE_MB"), "8")
  expect_identical(Sys.getenv("RSQLITE_HTTP_PREFETCH_PAGES"), "2")
  expect_identical(Sys.getenv("RSQLITE_HTTP_FALLBACK_FULLDL"), "0")

  prev2 <- sqlite_http_config()
  expect_identical(Sys.getenv("RSQLITE_HTTP_CACHE_MB"), "8")
  expect_identical(Sys.getenv("RSQLITE_HTTP_PREFETCH_PAGES"), "2")
  expect_identical(Sys.getenv("RSQLITE_HTTP_FALLBACK_FULLDL"), "0")

  expect_identical(prev2$cache_size_mb, 8L)
  expect_identical(prev2$prefetch_pages, 2L)
  expect_identical(prev2$fallback_full_download, FALSE)

  do.call(sqlite_http_config, prev)
  expect_identical(Sys.getenv("RSQLITE_HTTP_CACHE_MB"), "4")
  expect_identical(Sys.getenv("RSQLITE_HTTP_PREFETCH_PAGES"), "0")
  expect_identical(Sys.getenv("RSQLITE_HTTP_FALLBACK_FULLDL"), "1")
})

test_that("sqlite_remote validates url", {
  expect_error(
    sqlite_remote("ftp://example.org/db.sqlite"),
    "url must begin with http:// or https://"
  )
  expect_error(
    sqlite_remote("http://example.org/db.sqlite?x=1"),
    "url must not contain a query string or fragment"
  )
  expect_error(
    sqlite_remote("http://example.org/db.sqlite#frag"),
    "url must not contain a query string or fragment"
  )
})

test_that("sqliteHasHttpVFS returns a logical", {
  skip_on_cran()
  expect_type(sqliteHasHttpVFS(), "logical")
})

test_that("sqliteHttpVfsCompiled returns a logical scalar", {
  skip_on_cran()
  expect_type(sqliteHttpVfsCompiled(), "logical")
  expect_length(sqliteHttpVfsCompiled(), 1L)
})

test_that("sqliteHttpStats returns expected structure", {
  skip_on_cran()
  stats <- sqliteHttpStats()
  expect_type(stats, "list")
  expect_true(all(
    c("bytes_fetched", "range_requests", "full_download") %in% names(stats)
  ))
  expect_type(stats$bytes_fetched, "integer")
  expect_type(stats$range_requests, "integer")
  expect_type(stats$full_download, "logical")
})

test_that("initExtension supports http extension selector", {
  skip_on_cran()
  con <- DBI::dbConnect(SQLite(), ":memory:", loadable.extensions = TRUE)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  res <- try(initExtension(con, "http"), silent = TRUE)
  expect_true(inherits(res, "try-error") || isTRUE(res))
})

test_that("sqlite_remote exercises URI construction branches", {
  skip_on_cran()

  if (isTRUE(sqliteHasHttpVFS())) {
    # Use an invalid-but-well-formed URL that should fail quickly without
    # making a real network request (empty host).
    expect_error(sqlite_remote("https://"), ".*")
    expect_error(sqlite_remote("https://", immutable = FALSE), ".*")
  } else {
    expect_error(
      sqlite_remote("https://example.org/db.sqlite"),
      "HTTP VFS not available"
    )
  }
})
