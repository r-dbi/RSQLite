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

  # stdev() comes from the default extension, which sqliteRemote() loads.
  res <- dbGetQuery(
    con,
    "SELECT sum(x) AS s, count(*) AS n, stdev(x) AS sd FROM t WHERE x <= 5"
  )
  expect_equal(res$n[[1]], 5L)
  expect_equal(res$sd[[1]], sd(1:5))
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

test_that("http VFS gives up on a server that never answers", {
  skip_if_no_http_vfs()

  withr::local_envvar(RSQLITE_HTTP_STALL_TIMEOUT = "1")

  server <- local_http_server(raw(), ranges = FALSE, answer = FALSE)

  time <- system.time(
    expect_error(sqliteRemote(server$url), "unable to open database file")
  )
  # The default stall timeout is a minute.
  expect_lt(time[["elapsed"]], 30)
  # The server got the HEAD, so the open stalled instead of failing to connect.
  expect_equal(server$requests(), "HEAD")
})

test_that("an interrupt aborts a transfer to a server that never answers", {
  skip_if_no_http_vfs()
  skip_if(getRversion() < "4.0")

  # The session inherits this, so that only the interrupt can end the open early.
  withr::local_envvar(RSQLITE_HTTP_STALL_TIMEOUT = "60")
  server <- local_http_server(raw(), ranges = FALSE, answer = FALSE)
  session <- local_rsqlite_session()

  session$call(
    function(url) {
      start <- Sys.time()
      msg <- tryCatch(
        {
          RSQLite::sqliteRemote(url)
          "opened"
        },
        error = conditionMessage
      )
      list(
        msg = msg,
        elapsed = as.numeric(Sys.time() - start, units = "secs")
      )
    },
    list(url = server$url)
  )

  # An interrupt before the transfer starts would be an ordinary R interrupt.
  deadline <- Sys.time() + 30
  while (!("HEAD" %in% server$requests())) {
    if (session$poll_process(50) != "timeout") {
      stop("The session finished before its request reached the server")
    }
    if (Sys.time() > deadline) {
      stop("No request reached the server within 30 seconds")
    }
  }

  expect_true(session$interrupt())
  expect_equal(session$poll_process(10000), "ready")
  out <- session$read()
  expect_null(out$error)
  expect_match(out$result$msg, "unable to open database file")
  # The stall timeout is a minute.
  expect_lt(out$result$elapsed, 30)
})
