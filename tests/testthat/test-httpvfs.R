test_that("http VFS availability query works", {
  skip_on_cran()
  expect_type(sqliteHasHttpVFS(), "logical")
})

test_that("http VFS can read a small db via local HTTP server", {
  skip_on_cran()
  if (!sqliteHasHttpVFS()) skip("http VFS not available")
  if (!requireNamespace("httpuv", quietly = TRUE)) skip("httpuv not installed")

  # Create a tiny SQLite database on disk
  path <- tempfile(fileext = ".sqlite")
  con <- dbConnect(SQLite(), path)
  on.exit(try(dbDisconnect(con), silent = TRUE), add = TRUE)
  DBI::dbExecute(con, "CREATE TABLE t(x INTEGER);")
  DBI::dbExecute(con, "INSERT INTO t VALUES (1), (2), (3);")
  dbDisconnect(con)

  raw <- readBin(path, what = "raw", n = file.info(path)$size)

  # Serve the file via httpuv
  app <- list(
    call = function(req){
      list(
        status = 200L,
        headers = list(
          'Content-Type' = 'application/octet-stream',
          'Content-Length' = as.character(length(raw))
        ),
        body = raw
      )
    }
  )
  port <- httpuv::randomPort()
  server <- httpuv::startServer("127.0.0.1", port, app)
  on.exit(try(httpuv::stopServer(server), silent = TRUE), add = TRUE)

  url <- sprintf("http://127.0.0.1:%d/db.sqlite?vfs=http&immutable=1", port)
  rcon <- dbConnect(SQLite(), url, flags = SQLITE_RO)
  on.exit(try(dbDisconnect(rcon), silent = TRUE), add = TRUE)

  res <- dbGetQuery(rcon, "SELECT count(*) AS n FROM t")
  expect_equal(res$n[[1]], 3L)
})

test_that("http VFS uses HTTP Range requests when available", {
  skip_on_cran()
  if (!sqliteHasHttpVFS()) skip("http VFS not available")
  if (!requireNamespace("httpuv", quietly = TRUE)) skip("httpuv not installed")

  # Build a small DB
  path <- tempfile(fileext = ".sqlite")
  con <- dbConnect(SQLite(), path)
  on.exit(try(dbDisconnect(con), silent = TRUE), add = TRUE)
  DBI::dbExecute(con, "CREATE TABLE t(x INTEGER PRIMARY KEY, y TEXT);")
  DBI::dbExecute(con, "INSERT INTO t(x,y) VALUES (1,'a'),(2,'b'),(3,'c'),(4,'d'),(5,'e');")
  dbDisconnect(con)

  raw <- readBin(path, what = "raw", n = file.info(path)$size)

  served <- new.env(parent = emptyenv())
  served$total <- 0L
  app <- list(
    call = function(req){
      rng <- req$HTTP_RANGE
      total <- length(raw)
      if (!is.null(rng) && grepl("^bytes=", rng)) {
        m <- regexec("bytes=([0-9]+)-([0-9]+)?", rng)
        g <- regmatches(rng, m)[[1]]
        start <- as.integer(g[2])
        stop <- if (!is.na(g[3])) as.integer(g[3]) else (total - 1L)
        start <- max(start, 0L); stop <- min(stop, total - 1L)
        body <- raw[(start+1L):(stop+1L)]
        served$total <- served$total + length(body)
        list(
          status = 206L,
          headers = list(
            'Accept-Ranges' = 'bytes',
            'Content-Type' = 'application/octet-stream',
            'Content-Length' = as.character(length(body)),
            'Content-Range' = sprintf('bytes %d-%d/%d', start, stop, total)
          ),
          body = body
        )
      } else {
        served$total <- served$total + length(raw)
        list(
          status = 200L,
          headers = list(
            'Accept-Ranges' = 'bytes',
            'Content-Type' = 'application/octet-stream',
            'Content-Length' = as.character(length(raw))
          ),
          body = raw
        )
      }
    }
  )
  port <- httpuv::randomPort()
  server <- httpuv::startServer("127.0.0.1", port, app)
  on.exit(try(httpuv::stopServer(server), silent = TRUE), add = TRUE)

  # Disable fallback to full download to force Range path; keep cache small
  old_env <- Sys.getenv(c("RSQLITE_HTTP_FALLBACK_FULLDL","RSQLITE_HTTP_CACHE_MB","RSQLITE_HTTP_PREFETCH_PAGES"))
  on.exit(do.call(Sys.setenv, as.list(old_env)), add = TRUE)
  Sys.setenv(RSQLITE_HTTP_FALLBACK_FULLDL = "0", RSQLITE_HTTP_CACHE_MB = "1", RSQLITE_HTTP_PREFETCH_PAGES = "0")

  url <- sprintf("http://127.0.0.1:%d/db.sqlite?vfs=http&immutable=1", port)
  rcon <- dbConnect(SQLite(), url, flags = SQLITE_RO)
  on.exit(try(dbDisconnect(rcon), silent = TRUE), add = TRUE)

  res <- dbGetQuery(rcon, "SELECT sum(x) AS s, count(*) AS n FROM t WHERE x <= 5")
  expect_equal(res$n[[1]], 5L)
  # Expect we served less than the full file if Range was used
  expect_lt(unname(served$total), length(raw))

  stats <- sqliteHttpStats()
  expect_true(is.list(stats))
  expect_gt(stats$range_requests, 0L)
  expect_false(isTRUE(stats$full_download))
  expect_gt(stats$bytes_fetched, 0L)
})

test_that("http VFS fails open without Range when fallback disabled", {
  skip_on_cran()
  if (!sqliteHasHttpVFS()) skip("http VFS not available")
  if (!requireNamespace("httpuv", quietly = TRUE)) skip("httpuv not installed")

  # Build a small DB
  path <- tempfile(fileext = ".sqlite")
  con <- dbConnect(SQLite(), path)
  on.exit(try(dbDisconnect(con), silent = TRUE), add = TRUE)
  DBI::dbExecute(con, "CREATE TABLE t(x INTEGER);")
  DBI::dbExecute(con, "INSERT INTO t VALUES (1),(2),(3);")
  dbDisconnect(con)

  raw <- readBin(path, what = "raw", n = file.info(path)$size)

  # Server that deliberately omits Accept-Ranges and ignores Range header
  app <- list(
    call = function(req){
      list(
        status = 200L,
        headers = list(
          'Content-Type' = 'application/octet-stream',
          'Content-Length' = as.character(length(raw))
        ),
        body = raw
      )
    }
  )
  port <- httpuv::randomPort()
  server <- httpuv::startServer("127.0.0.1", port, app)
  on.exit(try(httpuv::stopServer(server), silent = TRUE), add = TRUE)

  # Disable fallback so open should fail (Range unsupported)
  old_env <- Sys.getenv(c("RSQLITE_HTTP_FALLBACK_FULLDL","RSQLITE_HTTP_CACHE_MB","RSQLITE_HTTP_PREFETCH_PAGES"))
  on.exit(do.call(Sys.setenv, as.list(old_env)), add = TRUE)
  Sys.setenv(RSQLITE_HTTP_FALLBACK_FULLDL = "0", RSQLITE_HTTP_CACHE_MB = "1", RSQLITE_HTTP_PREFETCH_PAGES = "0")

  url <- sprintf("http://127.0.0.1:%d/db.sqlite?vfs=http&immutable=1", port)
  expect_error(dbConnect(SQLite(), url, flags = SQLITE_RO), "HTTP VFS")
})
