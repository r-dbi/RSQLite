# The data frame path through Arrow: enabled by `dbConnect(arrow = TRUE)`.
#
# Rows are fetched as Arrow arrays and converted with one set of rules, and
# data frames are written as Arrow streams; the data frames are the same as on
# the default path.

# The number of rows per array of a fetch
ARROW_DF_CHUNK_SIZE <- 65536

# dbFetch() through Arrow: `n` rows as a data frame, all rows for `n < 0`.
# The rows are fetched first, as arrays typed for this fetch the way the
# default path types it, so that the columns are allocated once with the row
# count known.
arrow_fetch_df <- function(res, n, chunk_size = ARROW_DF_CHUNK_SIZE) {
  # The C++ code takes a 64-bit integer, doubles are whole numbers up to 2^53
  n <- min(n, 2^53)
  fetched <- result_fetch_arrow_df(res@ptr, n, chunk_size)
  df <- arrow_to_df(fetched$stream, res@conn, fetched$n, fetched$wide_ints)

  if (length(df) == 0L) {
    # Same warning as the default path, which gives none for `n = 0`
    if (n != 0) {
      warningc(
        "`dbGetQuery()`, `dbSendQuery()` and `dbFetch()` should only be used ",
        "with `SELECT` queries. Did you mean `dbExecute()`, `dbSendStatement()` ",
        "or `dbGetRowsAffected()`?"
      )
    }
    df <- data.frame()
  }

  df
}

# The unified conversion of an Arrow stream of `size` rows to a data frame,
# `wide_ints` tells which columns have needed 64-bit integers in this fetch or
# an earlier one
arrow_to_df <- function(stream, conn, size, wide_ints) {
  schema <- nanoarrow::infer_nanoarrow_schema(stream)
  ptype <- arrow_df_ptype(schema)
  df <- arrow_stream_to_df(stream, ptype, size)
  arrow_df_int64(df, conn@bigint, wide_ints)
}

# All rows of a stream with a known row count as a data frame:
# the columns are allocated once, each array is converted and copied into
# them and released before the next one is requested, so that the arrays go
# as the data frame fills up
arrow_stream_to_df <- function(stream, ptype, size) {
  size <- as.integer(size)
  columns <- lapply(ptype, function(col) vector(typeof(col), size))
  offset <- 0L
  repeat {
    array <- stream$get_next(validate = FALSE)
    if (is.null(array)) {
      break
    }
    n <- as.integer(array$length)
    if (n > 0L) {
      chunk <- nanoarrow::convert_array(array, to = ptype)
      idx <- offset + seq_len(n)
      for (j in seq_along(columns)) {
        values <- chunk[[j]]
        attributes(values) <- NULL
        columns[[j]][idx] <- values
      }
      offset <- offset + n
    }
    nanoarrow::nanoarrow_pointer_release(array)
  }
  stream$release()

  for (j in seq_along(columns)) {
    attributes(columns[[j]]) <- attributes(ptype[[j]])
  }
  names(columns) <- names(ptype)
  attr(columns, "row.names") <- .set_row_names(size)
  class(columns) <- "data.frame"
  columns
}

# The R types that Arrow columns are converted to:
# nanoarrow's own rules, except that 64-bit integers keep their range
# and null columns are logical
arrow_df_ptype <- function(schema) {
  ptype <- nanoarrow::infer_nanoarrow_ptype(schema)
  formats <- vapply(schema$children, function(child) child$format, character(1))
  for (i in which(formats %in% c("l", "L"))) {
    ptype[[i]] <- bit64::integer64()
  }
  for (i in which(formats == "n")) {
    ptype[[i]] <- logical()
  }
  ptype
}

# SQLite integers are 64-bit: a column whose values all fit is an integer,
# the others follow the `bigint` connection argument, like the default path,
# which also keeps a column that needed 64 bits in an earlier fetch
arrow_df_int64 <- function(df, bigint, wide_ints) {
  is_int64 <- which(vlapply(df, inherits, "integer64") & !wide_ints)
  for (i in is_int64) {
    as_int <- integer64_to_integer(df[[i]])
    if (!is.null(as_int)) {
      df[[i]] <- as_int
    }
  }
  convert_bigint(df, bigint)
}

# dbAppendTable() through Arrow: the data frame is written as an Arrow stream
arrow_append_df <- function(conn, name, value) {
  value <- arrow_prepare_df(value)
  dbAppendTableArrow(conn, name, nanoarrow::as_nanoarrow_array_stream(value))
}

# What the default path does in sqlData() and dbBind() before writing:
# factors become strings, lists of raw vectors become blobs
arrow_prepare_df <- function(value) {
  value <- factor_to_string(value, warn = TRUE)

  is_list <- vlapply(value, function(x) is.list(x) && !is.data.frame(x) && !inherits(x, "blob"))
  value[is_list] <- lapply(value[is_list], function(x) {
    x <- unclass(x)
    if (!all(vlapply(x, function(elt) is.null(elt) || is.raw(elt)))) {
      stopc("Can only write lists of raw vectors (or NULL)")
    }
    blob::as_blob(x)
  })

  is_posixlt <- vlapply(value, inherits, "POSIXlt")
  value[is_posixlt] <- lapply(value[is_posixlt], as.POSIXct)

  value
}
