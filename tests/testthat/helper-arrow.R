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

# Lowers the bytes of a string or binary column after which, or beyond which,
# a chunk ends, from 1 GiB and 2^31 - 1
local_arrow_bytes_limits <- function(cut_bytes, max_bytes, envir = parent.frame()) {
  old <- arrow_set_bytes_limits(cut_bytes, max_bytes)
  withr::defer(arrow_set_bytes_limits(old[[1]], old[[2]]), envir = envir)
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
