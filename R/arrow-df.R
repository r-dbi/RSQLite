# The data frame path through Arrow: enabled by `dbConnect(arrow = TRUE)`.
#
# Rows are fetched as Arrow arrays and converted with one set of rules, and
# data frames are written as Arrow streams; the data frames are the same as on
# the default path.

# The number of rows per array when a whole result is fetched
ARROW_DF_CHUNK_SIZE <- 65536

# dbFetch() through Arrow: `n` rows as a data frame, all rows for `n < 0`,
# with the columns of `ptype` converted to its types
arrow_fetch_df <- function(res, n, ptype = NULL) {
  if (n < 0) {
    x <- result_fetch_arrow(res@ptr, ARROW_DF_CHUNK_SIZE)
  } else {
    x <- result_fetch_arrow_chunk(res@ptr, n)
  }
  df <- arrow_to_df(x, res@conn, ptype)

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

# The unified conversion of Arrow data to a data frame:
# the columns of `ptype` become its types, the others follow arrow_df_ptype()
arrow_to_df <- function(x, conn, ptype = NULL) {
  schema <- nanoarrow::infer_nanoarrow_schema(x)
  to <- arrow_df_ptype(schema)

  # nanoarrow builds factors only from given levels, the others come from the values
  factors <- character()
  for (name in names(ptype)) {
    col <- ptype[[name]]
    if (is.factor(col) && length(levels(col)) == 0) {
      factors <- c(factors, name)
      col <- character()
    }
    to[[name]] <- col
  }

  if (inherits(x, "nanoarrow_array_stream")) {
    df <- nanoarrow::convert_array_stream(x, to = to)
  } else {
    df <- nanoarrow::convert_array(x, to = to)
  }
  for (name in factors) {
    df[[name]] <- factor(df[[name]])
  }

  arrow_df_int64(df, conn@bigint, keep = names(ptype))
}

# A data frame prototype from a data frame or a named list of vectors:
# zero rows, POSIXlt as POSIXct
arrow_check_ptype <- function(ptype) {
  if (is.data.frame(ptype)) {
    columns <- as.list(ptype[0, , drop = FALSE])
  } else if (is.list(ptype)) {
    columns <- ptype
  } else {
    stopc("`ptype` must be a data frame or a named list of vectors")
  }
  if (length(columns) == 0 || is.null(names(columns)) || any(names(columns) == "")) {
    stopc("All columns of `ptype` must be named")
  }
  if (anyDuplicated(names(columns))) {
    stopc(
      "Duplicate column names in `ptype`: ",
      paste0("`", unique(names(columns)[duplicated(names(columns))]), "`", collapse = ", ")
    )
  }
  columns <- lapply(columns, function(col) {
    if (is.data.frame(col)) {
      stopc("The columns of `ptype` must be vectors, not data frames")
    }
    if (is.raw(col)) {
      stopc("A raw vector in `ptype` does not describe a column, use `blob::blob()` for binary columns")
    }
    if (inherits(col, "POSIXlt")) {
      col <- as.POSIXct(col)
    }
    col[0]
  })
  structure(columns, class = "data.frame", row.names = integer())
}

# The Arrow types to request for the columns of a prototype:
# nanoarrow's inference, except that hms columns take the time64 type the
# result path fills, and factors are read as strings
arrow_ptype_schema <- function(ptype) {
  children <- lapply(ptype, function(col) {
    if (inherits(col, "hms")) {
      nanoarrow::na_time64("us")
    } else if (is.factor(col)) {
      nanoarrow::na_string()
    } else {
      nanoarrow::infer_nanoarrow_schema(col)
    }
  })
  nanoarrow::na_struct(children)
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
# the others follow the `bigint` connection argument, like the default path;
# the columns in `keep` have their requested type already
arrow_df_int64 <- function(df, bigint, keep = character()) {
  is_int64 <- which(vlapply(df, inherits, "integer64") & !(names(df) %in% keep))
  for (i in is_int64) {
    x <- df[[i]]
    if (all(is.na(x) | (x >= -.Machine$integer.max & x <= .Machine$integer.max))) {
      df[[i]] <- as.integer(x)
    }
  }
  kept <- df[keep]
  df <- convert_bigint(df, bigint)
  df[keep] <- kept
  df
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
