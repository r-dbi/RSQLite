test_that("http VFS availability query works", {
  skip_on_cran()
  expect_type(sqliteHasHttpVFS(), "logical")
})

test_that("http VFS can read a small db via local HTTP server", {
  skip_if_no_http_vfs()

  # This server ignores Range requests, so the VFS downloads the whole file.
  server <- local_http_server(
    http_test_db(c(
      "CREATE TABLE t(x INTEGER);",
      "INSERT INTO t VALUES (1), (2), (3);"
    )),
    ranges = FALSE
  )

  # Also loads the default extensions through the HTTP VFS.
  con <- dbConnect(SQLite(), http_vfs_uri(server$url), flags = SQLITE_RO)
  withr::defer(dbDisconnect(con))

  res <- dbGetQuery(con, "SELECT count(*) AS n FROM t")
  expect_equal(res$n[[1]], 3L)
})

test_that("http VFS uses HTTP Range requests when available", {
  skip_if_no_http_vfs()

  # Disable fallback to full download to force Range path; keep cache small
  withr::local_envvar(
    RSQLITE_HTTP_FALLBACK_FULLDL = "0",
    RSQLITE_HTTP_CACHE_MB = "1",
    RSQLITE_HTTP_PREFETCH_PAGES = "0"
  )

  # The padding table makes the file much larger than the pages the query reads.
  body <- http_test_db(c(
    "CREATE TABLE t(x INTEGER PRIMARY KEY, y TEXT);",
    "INSERT INTO t(x,y) VALUES (1,'a'),(2,'b'),(3,'c'),(4,'d'),(5,'e');",
    "CREATE TABLE padding(b BLOB);",
    "INSERT INTO padding VALUES (zeroblob(100000));"
  ))
  server <- local_http_server(body, ranges = TRUE)

  # The counters are process-wide, so compare against their earlier values.
  before <- sqliteHttpStats()

  con <- sqliteRemote(server$url)
  withr::defer(dbDisconnect(con))

  res <- dbGetQuery(con, "SELECT sum(x) AS s, count(*) AS n FROM t WHERE x <= 5")
  expect_equal(res$n[[1]], 5L)
  # Expect we served less than the full file if Range was used
  expect_lt(server$bytes_sent(), length(body))

  stats <- sqliteHttpStats()
  expect_gt(stats$range_requests, before$range_requests)
  expect_gt(stats$bytes_fetched, before$bytes_fetched)
})

test_that("http VFS fails open without Range when fallback disabled", {
  skip_if_no_http_vfs()

  # Disable fallback so open should fail (Range unsupported)
  withr::local_envvar(RSQLITE_HTTP_FALLBACK_FULLDL = "0")

  server <- local_http_server(
    http_test_db("CREATE TABLE t(x INTEGER);"),
    ranges = FALSE
  )

  # Opening reads the file header, which needs a Range request.
  expect_error(sqliteRemote(server$url), "disk I/O error")
})
