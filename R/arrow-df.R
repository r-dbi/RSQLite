# The data frame path through Arrow: enabled by `dbConnect(arrow = TRUE)`.
#
# Rows are fetched as Arrow arrays and converted with one set of rules, and
# data frames are written as Arrow streams; the data frames are the same as on
# the default path.

# The number of rows per array when a whole result is fetched
ARROW_DF_CHUNK_SIZE <- 65536

# dbFetch() through Arrow: `n` rows as a data frame, all rows for `n < 0`
arrow_fetch_df <- function(res, n) {
  if (n < 0) {
    x <- result_fetch_arrow(res@ptr, ARROW_DF_CHUNK_SIZE)
  } else {
    x <- result_fetch_arrow_chunk(res@ptr, n)
  }
  df <- arrow_to_df(x, res@conn)

  if (length(df) == 0L) {
    # Same warning as the default path
    warningc(
      "`dbGetQuery()`, `dbSendQuery()` and `dbFetch()` should only be used ",
      "with `SELECT` queries. Did you mean `dbExecute()`, `dbSendStatement()` ",
      "or `dbGetRowsAffected()`?"
    )
    df <- data.frame()
  }

  df
}

# The unified conversion of Arrow data to a data frame
arrow_to_df <- function(x, conn) {
  schema <- nanoarrow::infer_nanoarrow_schema(x)
  ptype <- arrow_df_ptype(schema)

  if (inherits(x, "nanoarrow_array_stream")) {
    df <- nanoarrow::convert_array_stream(x, to = ptype)
  } else {
    df <- nanoarrow::convert_array(x, to = ptype)
  }

  arrow_df_int64(df, conn@bigint)
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
# the others follow the `bigint` connection argument, like the default path
arrow_df_int64 <- function(df, bigint) {
  is_int64 <- which(vlapply(df, inherits, "integer64"))
  for (i in is_int64) {
    x <- df[[i]]
    if (all(is.na(x) | (x >= -.Machine$integer.max & x <= .Machine$integer.max))) {
      df[[i]] <- as.integer(x)
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
