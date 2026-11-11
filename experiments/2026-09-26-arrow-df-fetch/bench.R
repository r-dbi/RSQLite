# Fetch benchmark for RSQLite: the default data frame path against the Arrow path.
#
# Measures how long it takes to move a query result from SQLite into an R data
# frame, and the peak memory of the move, per fetch strategy, for a table whose
# row count the fetch cannot know in advance: SQLite reports no count before
# the last step, so every column buffer has to grow as the rows arrive.
#
# Usage:
#   Rscript bench.R [--rows=1000000] [--reps=3] [--chunk=10000]
#                   [--out=results.csv] [--db=<path to create or reuse>]
#                   [--strategies=a,b,...] [--queries=a,b,...]
#
# Every strategy x query cell runs in a fresh R subprocess (callr), so that
# the peak RSS (VmHWM on Linux) is the cell's own. The table is created once,
# deterministically, and reused when --db names an existing file.
#
# Strategies:
#   baseline          connect and run the query behind a LIMIT 0: the floor a
#                     subprocess pays for R, the packages and the connection
#   default           dbGetQuery() on a default connection: the C++ path fills
#                     R vectors directly, growing them as rows arrive
#   arrow_df          dbGetQuery() on dbConnect(arrow = TRUE): Arrow arrays of
#                     65536 rows, converted by nanoarrow into one data frame
#   arrow_stream      as.data.frame(dbGetQueryArrow()): the explicit Arrow
#                     route with nanoarrow's own conversion (int64 columns stay
#                     integer64), the cost the Arrow path builds on
#   default_chunked   dbSendQuery() + dbFetch(n = chunk) loop, batches
#                     discarded: the bounded-memory consumer, default path
#   arrow_df_chunked  the same loop on dbConnect(arrow = TRUE)
#   arrow_drain       dbSendQueryArrow() + dbFetchArrowChunk() loop without
#                     converting to R: the cost of filling the arrays alone
#
# Queries:
#   all       SELECT * FROM t: all five columns, mixed types, NULLs
#   numbers   the integer and real columns
#   strings   the two text columns: string allocation bound
#   filtered  SELECT * FROM t WHERE x < 0.3: about a third of the rows

args <- commandArgs(trailingOnly = TRUE)

arg <- function(name, default = NULL) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) {
    return(default)
  }
  sub(paste0("^--", name, "="), "", hit[[1]])
}

rows <- as.integer(arg("rows", "1000000"))
reps <- as.integer(arg("reps", "3"))
chunk <- as.integer(arg("chunk", "10000"))
out <- arg("out", "results.csv")
db <- arg("db", tempfile(fileext = ".sqlite"))

STRATEGIES <- c(
  "baseline", "default", "arrow_df", "arrow_stream",
  "default_chunked", "arrow_df_chunked", "arrow_drain"
)
QUERIES <- c(
  all = "SELECT * FROM t",
  numbers = "SELECT id, n, x FROM t",
  strings = "SELECT s, t FROM t",
  filtered = "SELECT * FROM t WHERE x < 0.3"
)

strategies <- strsplit(arg("strategies", paste(STRATEGIES, collapse = ",")), ",")[[1]]
queries <- strsplit(arg("queries", paste(names(QUERIES), collapse = ",")), ",")[[1]]
stopifnot(strategies %in% STRATEGIES, queries %in% names(QUERIES))

# --- the table --------------------------------------------------------------

# Five columns: a row id, an integer with 10 % NULLs, a real in [0, 1),
# a short key string, and a three-word string with 20 % NULLs.
make_table <- function(db, rows) {
  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  on.exit(DBI::dbDisconnect(con))
  set.seed(20260926)
  vocab <- vapply(seq_len(200), function(i) {
    paste(sample(letters, sample(6:12, 1), replace = TRUE), collapse = "")
  }, character(1))
  DBI::dbExecute(con, "CREATE TABLE t (id INTEGER, n INTEGER, x REAL, s TEXT, t TEXT)")
  batch <- 100000L
  DBI::dbWithTransaction(con, {
    for (start in seq(1L, rows, by = batch)) {
      ids <- start:min(start + batch - 1L, rows)
      size <- length(ids)
      n <- sample.int(1000000L, size, replace = TRUE)
      n[runif(size) < 0.1] <- NA_integer_
      t <- paste(
        vocab[sample.int(200L, size, replace = TRUE)],
        vocab[sample.int(200L, size, replace = TRUE)],
        vocab[sample.int(200L, size, replace = TRUE)]
      )
      t[runif(size) < 0.2] <- NA_character_
      DBI::dbAppendTable(con, "t", data.frame(
        id = ids,
        n = n,
        x = runif(size),
        s = sprintf("k%06d", sample.int(100000L, size, replace = TRUE)),
        t = t,
        stringsAsFactors = FALSE
      ))
    }
  })
  invisible(db)
}

# --- one cell, in a fresh process ---------------------------------------------

run_cell <- function(strategy, sql, db, chunk) {
  library(DBI)
  library(RSQLite)

  peak_rss_mb <- function() {
    if (!file.exists("/proc/self/status")) {
      return(NA_real_)
    }
    line <- grep("^VmHWM:", readLines("/proc/self/status"), value = TRUE)
    as.numeric(sub("^VmHWM:\\s+(\\d+) kB", "\\1", line)) / 1024
  }

  arrow <- strategy %in% c("arrow_df", "arrow_df_chunked")
  con <- dbConnect(SQLite(), db, arrow = arrow)
  on.exit(dbDisconnect(con))

  n_rows <- 0
  df_mb <- NA_real_
  start <- proc.time()[["elapsed"]]
  switch(strategy,
    baseline = {
      df <- dbGetQuery(con, paste(sql, "LIMIT 0"))
      n_rows <- nrow(df)
    },
    default = ,
    arrow_df = {
      df <- dbGetQuery(con, sql)
      n_rows <- nrow(df)
      df_mb <- as.numeric(object.size(df)) / 2^20
    },
    arrow_stream = {
      df <- as.data.frame(dbGetQueryArrow(con, sql))
      n_rows <- nrow(df)
      df_mb <- as.numeric(object.size(df)) / 2^20
    },
    default_chunked = ,
    arrow_df_chunked = {
      rs <- dbSendQuery(con, sql)
      while (!dbHasCompleted(rs)) {
        n_rows <- n_rows + nrow(dbFetch(rs, chunk))
      }
      dbClearResult(rs)
    },
    arrow_drain = {
      rs <- dbSendQueryArrow(con, sql)
      while (!dbHasCompleted(rs)) {
        n_rows <- n_rows + dbFetchArrowChunk(rs, chunk_size = chunk)$length
      }
      dbClearResult(rs)
    }
  )
  elapsed <- proc.time()[["elapsed"]] - start

  data.frame(
    elapsed = elapsed,
    rows = n_rows,
    df_mb = df_mb,
    peak_rss_mb = peak_rss_mb(),
    rsqlite = as.character(packageVersion("RSQLite")),
    stringsAsFactors = FALSE
  )
}

# --- the grid -------------------------------------------------------------------

if (!file.exists(db)) {
  cat("Creating", format(rows, big.mark = ","), "rows in", db, "\n")
  make_table(db, rows)
}

results <- list()
for (rep in seq_len(reps)) {
  for (query in queries) {
    for (strategy in strategies) {
      cell <- callr::r(
        run_cell,
        args = list(strategy = strategy, sql = QUERIES[[query]], db = db, chunk = chunk),
        libpath = .libPaths()
      )
      cell <- cbind(rep = rep, query = query, strategy = strategy, cell, stringsAsFactors = FALSE)
      cat(sprintf(
        "rep %d  %-9s %-17s %7.2f s  %8.0f rows  peak %6.0f MB\n",
        rep, query, strategy, cell$elapsed, cell$rows, cell$peak_rss_mb
      ))
      results[[length(results) + 1]] <- cell
    }
  }
}
results <- do.call(rbind, results)
results$table_rows <- rows
results$chunk <- chunk
results$platform <- R.version$platform
results$r <- R.version.string
results$nanoarrow <- as.character(packageVersion("nanoarrow"))
results$sqlite <- RSQLite::rsqliteVersion()[[1]]
results$date <- format(Sys.Date())
write.csv(results, out, row.names = FALSE)
cat("\nWritten", out, "\n\n")

# --- the summary: medians per cell, as a Markdown table -------------------------

med <- aggregate(
  cbind(elapsed, peak_rss_mb, df_mb, rows) ~ query + strategy,
  data = results, FUN = median, na.action = na.pass
)
med$strategy <- factor(med$strategy, levels = STRATEGIES)
med$query <- factor(med$query, levels = names(QUERIES))
med <- med[order(med$query, med$strategy), ]
baseline <- med[med$strategy == "baseline", c("query", "peak_rss_mb")]
names(baseline)[2] <- "floor_mb"
med <- merge(med, baseline, by = "query", all.x = TRUE, sort = FALSE)
med <- med[order(med$query, med$strategy), ]

cat("| query | strategy | rows | seconds | peak RSS MB | above floor MB | data frame MB |\n")
cat("|---|---|---:|---:|---:|---:|---:|\n")
for (i in seq_len(nrow(med))) {
  cat(sprintf(
    "| %s | %s | %s | %.2f | %.0f | %.0f | %s |\n",
    med$query[i], med$strategy[i], formatC(med$rows[i], format = "d", big.mark = ","),
    med$elapsed[i], med$peak_rss_mb[i], med$peak_rss_mb[i] - med$floor_mb[i],
    if (is.na(med$df_mb[i])) "" else sprintf("%.0f", med$df_mb[i])
  ))
}
