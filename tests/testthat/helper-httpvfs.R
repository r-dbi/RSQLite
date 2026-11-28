skip_if_no_http_vfs <- function() {
  skip_on_cran()
  if (!sqliteHttpVfsCompiled()) {
    # CI sets this, so that losing libcurl fails instead of skipping.
    if (identical(Sys.getenv("RSQLITE_TEST_HTTPVFS"), "true")) {
      stop("HTTP VFS not compiled in, but RSQLITE_TEST_HTTPVFS is true")
    }
    skip("HTTP VFS not compiled in (configure did not find libcurl)")
  }
  skip_if_not_installed("httpuv")
  skip_if_not_installed("callr")

  # Registers the VFS, which must succeed once it is compiled in.
  if (!sqliteHasHttpVFS()) {
    stop("HTTP VFS is compiled in but could not be registered")
  }
}

# Returns the bytes of a new database file built by running `sql`.
http_test_db <- function(sql) {
  path <- withr::local_tempfile(fileext = ".sqlite")
  con <- dbConnect(SQLite(), path)
  withr::defer(dbDisconnect(con))
  for (statement in sql) {
    dbExecute(con, statement)
  }
  readBin(path, "raw", file.size(path))
}

# Serves `body` at the returned `url` until `.local_envir` exits,
# honoring Range requests only with `ranges = TRUE`,
# and accepting requests without ever answering them with `answer = FALSE`.
# `bytes_sent()` and `requests()` report the bytes sent and the methods seen.
# The server runs in a separate process,
# because the HTTP VFS blocks this one while it waits for a response.
local_http_server <- function(
  body,
  ranges,
  answer = TRUE,
  .local_envir = parent.frame()
) {
  dir <- withr::local_tempdir(.local_envir = .local_envir)
  body_path <- file.path(dir, "db.sqlite")
  writeBin(body, body_path)
  log_path <- file.path(dir, "sent.log")
  requests_path <- file.path(dir, "requests.log")
  port_path <- file.path(dir, "port")

  # The killed process leaves its session directory behind in its TMPDIR.
  server <- callr::r_bg(
    serve_http_file,
    list(body_path, ranges, answer, log_path, requests_path, port_path),
    env = c(callr::rcmd_safe_env(), TMPDIR = dir),
    supervise = TRUE
  )
  withr::defer(server$kill(), envir = .local_envir)
  withr::local_envvar(
    no_proxy = "127.0.0.1",
    NO_PROXY = "127.0.0.1",
    .local_envir = .local_envir
  )

  deadline <- Sys.time() + 30
  while (!file.exists(port_path)) {
    if (!server$is_alive()) {
      stop("HTTP test server failed: ", server$read_all_error())
    }
    if (Sys.time() > deadline) {
      stop("HTTP test server did not start within 30 seconds")
    }
    Sys.sleep(0.05)
  }

  list(
    url = sprintf("http://127.0.0.1:%s/db.sqlite", readLines(port_path)),
    bytes_sent = function() {
      if (!file.exists(log_path)) {
        return(0)
      }
      sum(as.numeric(readLines(log_path)))
    },
    requests = function() {
      if (!file.exists(requests_path)) {
        return(character())
      }
      readLines(requests_path)
    }
  )
}

# Runs in the server process started by local_http_server().
serve_http_file <- function(
  body_path,
  ranges,
  answer,
  log_path,
  requests_path,
  port_path
) {
  body <- readBin(body_path, "raw", file.size(body_path))
  total <- length(body)

  call <- function(req) {
    # One line per request, also for requests that are never answered.
    # While a request is not answered, no other request reaches this function.
    cat(req$REQUEST_METHOD, "\n", file = requests_path, append = TRUE, sep = "")
    if (!answer) {
      Sys.sleep(3600)
    }
    status <- 200L
    headers <- list("Content-Type" = "application/octet-stream")
    out <- body
    if (ranges) {
      headers[["Accept-Ranges"]] <- "bytes"
      range <- req$HTTP_RANGE
      if (is.null(range)) {
        range <- ""
      }
      m <- regmatches(range, regexec("^bytes=([0-9]+)-([0-9]*)$", range))[[1]]
      if (length(m) == 3L) {
        from <- as.numeric(m[[2]])
        to <- if (nzchar(m[[3]])) as.numeric(m[[3]]) else total - 1
        to <- min(to, total - 1)
        if (from <= to) {
          status <- 206L
          headers[["Content-Range"]] <- sprintf(
            "bytes %.0f-%.0f/%d",
            from,
            to,
            total
          )
          out <- body[seq(from + 1, to + 1)]
        }
      }
    }
    if (req$REQUEST_METHOD == "HEAD") {
      # httpuv would send the body even for HEAD,
      # which corrupts the next response on a kept-alive connection.
      headers[["Content-Length"]] <- as.character(length(out))
      return(list(status = status, headers = headers, body = NULL))
    }
    cat(length(out), "\n", file = log_path, append = TRUE)
    list(status = status, headers = headers, body = out)
  }

  server <- httpuv::startServer(
    "127.0.0.1",
    httpuv::randomPort(),
    list(call = call)
  )
  writeLines(as.character(server$getPort()), paste0(port_path, ".tmp"))
  file.rename(paste0(port_path, ".tmp"), port_path)
  repeat {
    httpuv::service(1000)
  }
}

http_vfs_uri <- function(url) {
  paste0("file:", url, "?vfs=http&immutable=1")
}
