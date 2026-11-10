# Helpers for the Arrow tests

local_con <- function(..., envir = parent.frame()) {
  con <- dbConnect(SQLite(), ":memory:", ...)
  withr::defer(dbDisconnect(con), envir = envir)
  con
}

local_arrow_con <- function(..., envir = parent.frame()) {
  con <- dbConnect(SQLite(), ":memory:", arrow = TRUE, ...)
  withr::defer(dbDisconnect(con), envir = envir)
  con
}

schema_formats <- function(x) {
  schema <- nanoarrow::infer_nanoarrow_schema(x)
  vapply(schema$children, function(child) child$format, character(1))
}

# The lengths of the arrays a stream yields, which are released on the way
chunk_lengths <- function(stream) {
  lengths <- numeric()
  repeat {
    array <- stream$get_next()
    if (is.null(array)) {
      break
    }
    lengths <- c(lengths, array$length)
    nanoarrow::nanoarrow_pointer_release(array)
  }
  lengths
}

# Lowers, for the result `rs` alone, the bytes of a string or binary column
# after which, or beyond which, a chunk ends, from 1 GiB and 2^31 - 1
set_bytes_limits <- function(rs, cut_bytes = 100, max_bytes = 150) {
  if (methods::is(rs, "SQLiteResultArrow")) {
    rs <- rs@result
  }
  result_set_bytes_limits(rs@ptr, cut_bytes, max_bytes)
}

# A lazy stream over `sql` with the byte limits lowered to 100 and 150,
# `...` goes to dbSendQueryArrow(); the stream reads on after its result has
# been cleared
fetch_with_bytes_limits <- function(con, sql, ...) {
  rs <- dbSendQueryArrow(con, sql, ...)
  on.exit(dbClearResult(rs))
  set_bytes_limits(rs)
  dbFetchArrow(rs)
}

# The coercion warnings that `expr` raises, muffled
coercion_warnings <- function(expr) {
  out <- list()
  withCallingHandlers(
    expr,
    RSQLite_warning_coercion = function(w) {
      out[[length(out) + 1]] <<- w
      invokeRestart("muffleWarning")
    }
  )
  out
}

# Checks an Arrow array, or each array of a stream, with arrow's ValidateFull()
# where arrow is installed, and returns an equivalent object: a stream is read
# to the end and comes back as a stream of the same arrays
arrow_validated <- function(x) {
  if (inherits(x, "nanoarrow_array_stream")) {
    schema <- x$get_schema()
    arrays <- list()
    repeat {
      array <- x$get_next()
      if (is.null(array)) {
        break
      }
      arrays[[length(arrays) + 1]] <- arrow_validated(array)
    }
    x$release()
    return(nanoarrow::basic_array_stream(arrays, schema = schema))
  }

  if (rlang::is_installed("arrow")) {
    if (nanoarrow::infer_nanoarrow_schema(x)$format == "+s") {
      table <- arrow::as_arrow_table(x)
    } else {
      table <- arrow::arrow_table(x = arrow::as_arrow_array(x))
    }
    testthat::expect_true(table$ValidateFull())
  }
  x
}

# The one array of a stream, without the arrow package that
# nanoarrow::as_nanoarrow_array() needs for a stream
single_array <- function(stream) {
  arrays <- nanoarrow::collect_array_stream(stream)
  testthat::expect_length(arrays, 1)
  arrays[[1]]
}
