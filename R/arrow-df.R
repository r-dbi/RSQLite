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
# count known; the columns of the result's `ptype` have their requested types.
arrow_fetch_df <- function(res, n, chunk_size = ARROW_DF_CHUNK_SIZE) {
  # The C++ code takes a 64-bit integer, doubles are whole numbers up to 2^53
  n <- min(n, 2^53)
  fetched <- result_fetch_arrow_df(res@ptr, n, chunk_size)

  if (length(fetched$names) == 0L) {
    # Same warning as the default path, which gives none for `n = 0`
    if (n != 0) {
      warningc(
        "`dbGetQuery()`, `dbSendQuery()` and `dbFetch()` should only be used ",
        "with `SELECT` queries. Did you mean `dbExecute()`, `dbSendStatement()` ",
        "or `dbGetRowsAffected()`?"
      )
    }
    return(data.frame())
  }

  df <- arrow_to_df(fetched, res@conn@bigint, res@ptype)
  # Last, once the result is ready for the next fetch: a handler of the warning
  # can use it, and an error raised from the warning only loses these rows
  if (!is.null(fetched$coercions)) {
    warn_coercion(fetched$coercions)
  }
  df
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
# nanoarrow's inference, except that hms columns take the time64 type of a
# decided time, and factors are read as strings
arrow_ptype_schema <- function(ptype) {
  nanoarrow::na_struct(Map(arrow_ptype_column_schema, ptype, names(ptype)))
}

# The columns of a prototype that data frame fetches read like a decided time
# or timestamp, as doubles in seconds with the default path's precision and
# range, and that get the prototype's class and time zone in arrow_to_df()
arrow_ptype_seconds <- function(ptype) {
  vlapply(ptype, inherits, c("hms", "POSIXct"), USE.NAMES = FALSE)
}

# A column that nanoarrow finds no type for, or can't convert back to,
# is an error that names it before the query is sent
arrow_ptype_column_schema <- function(col, name) {
  if (inherits(col, "hms")) {
    return(nanoarrow::na_time64("us"))
  }
  if (is.factor(col)) {
    return(nanoarrow::na_string())
  }
  schema <- tryCatch(
    nanoarrow::infer_nanoarrow_schema(col),
    error = function(e) {
      stopc("Can't request a type for column `", name, "` of `ptype`: ", conditionMessage(e))
    }
  )
  # nanoarrow infers a type for some classes it cannot convert back to, such as AsIs
  back <- tryCatch(
    nanoarrow::convert_array(nanoarrow::nanoarrow_array_init(schema), to = col),
    error = function(e) NULL
  )
  if (!identical(class(back), class(col))) {
    stopc(
      "Can't convert the values of column `", name, "` of `ptype` ",
      "to its class <", paste(class(col), collapse = "/"), ">"
    )
  }
  schema
}

# The unified conversion of the arrays of a fetch to a data frame.
# `fetched` holds the arrays with their lengths, the row count, the names and
# Arrow formats of the columns, which columns have needed 64-bit integers in
# this fetch or an earlier one, and the class of the columns of times and
# timestamps, which come as doubles in seconds like on the default path.
# The columns of `ptype` are converted to its types.
# The work is done on a plain list, small fetches pay for every R call.
arrow_to_df <- function(fetched, bigint, ptype = NULL) {
  formats <- fetched$formats
  to <- arrow_df_ptype(formats, fetched$names)
  arrays <- fetched$arrays

  # The names of `ptype` occur once in the result, see arrow_set_schema().
  # nanoarrow builds factors only from given levels, the others come from the
  # values, and times and timestamps in seconds take the prototype's
  # attributes after the conversion.
  requested <- match(names(ptype), fetched$names)
  keep <- logical(length(formats))
  keep[requested] <- TRUE
  factors <- vlapply(ptype, function(col) is.factor(col) && length(levels(col)) == 0)
  seconds <- fetched$seconds[requested] != ""
  for (i in which(!seconds)) {
    to[[requested[[i]]]] <- if (factors[[i]]) character() else ptype[[i]]
  }

  if (length(arrays) == 1L) {
    # One array holds all rows, such as a fetch of fewer rows than a chunk:
    # nanoarrow's columns are the data frame, except that its character
    # vectors read from the array until they are touched, so these are copied
    # before the array is released
    columns <- unclass(nanoarrow::convert_array(arrays[[1L]], to = to))
    for (j in which(formats %in% c("u", "U"))) {
      columns[[j]] <- c(columns[[j]])
    }
    nanoarrow::nanoarrow_pointer_release(arrays[[1L]])
  } else {
    columns <- arrow_arrays_to_columns(arrays, fetched$lengths, to, fetched$n)
  }
  for (i in which(factors)) {
    columns[[requested[[i]]]] <- factor(columns[[requested[[i]]]], ordered = is.ordered(ptype[[i]]))
  }

  for (j in which(fetched$seconds == "hms")) {
    columns[[j]] <- hms::new_hms(columns[[j]])
  }
  for (j in which(fetched$seconds == "POSIXct")) {
    columns[[j]] <- .POSIXct(columns[[j]], tz = "UTC")
  }
  for (i in which(seconds)) {
    attributes(columns[[requested[[i]]]]) <- attributes(ptype[[i]])
  }

  # SQLite integers are 64-bit: a column whose values all fit is an integer,
  # the others follow the `bigint` connection argument, like the default path,
  # which also keeps a column that needed 64 bits in an earlier fetch;
  # the columns of `ptype` have their types already
  is_int64 <- formats %in% c("l", "L") & !keep
  for (j in which(is_int64 & !fetched$wide_ints)) {
    as_int <- integer64_to_integer(columns[[j]])
    if (!is.null(as_int)) {
      columns[[j]] <- as_int
    }
  }
  if (bigint != "integer64" && any(is_int64)) {
    columns[!keep] <- convert_bigint(columns[!keep], bigint)
  }

  attr(columns, "row.names") <- .set_row_names(as.integer(fetched$n))
  class(columns) <- "data.frame"
  columns
}

# The columns of all rows of several arrays, as a list: the columns are
# allocated once, each array is converted and copied into them and released
# before the next one, so that the arrays go as the data frame fills up
arrow_arrays_to_columns <- function(arrays, lengths, ptype, size) {
  size <- as.integer(size)
  columns <- lapply(ptype, function(col) vector(typeof(col), size))
  offset <- 0L
  for (i in seq_along(arrays)) {
    n <- as.integer(lengths[[i]])
    if (n > 0L) {
      chunk <- nanoarrow::convert_array(arrays[[i]], to = ptype)
      idx <- offset + seq_len(n)
      for (j in seq_along(columns)) {
        values <- chunk[[j]]
        attributes(values) <- NULL
        columns[[j]][idx] <- values
      }
      offset <- offset + n
    }
    nanoarrow::nanoarrow_pointer_release(arrays[[i]])
  }

  for (j in seq_along(columns)) {
    attributes(columns[[j]]) <- attributes(ptype[[j]])
  }
  columns
}

# The zero-row data frame that the arrays of a fetch are converted to:
# nanoarrow's own rules for the formats a fetch produces, except that 64-bit
# integers keep their range and null columns are logical
arrow_df_ptype <- function(formats, names) {
  ptype <- lapply(formats, arrow_df_column_ptype)
  names(ptype) <- names
  attr(ptype, "row.names") <- integer()
  class(ptype) <- "data.frame"
  ptype
}

arrow_df_ptypes <- new.env(parent = emptyenv())

arrow_df_column_ptype <- function(format) {
  ptype <- arrow_df_ptypes[[format]]
  if (is.null(ptype)) {
    ptype <- switch(format,
      n = logical(),
      l = bit64::integer64(),
      g = double(),
      u = character(),
      z = blob::blob(),
      tdD = structure(double(), class = "Date"),
      ttu = hms::hms(),
      "tsu:UTC" = .POSIXct(double(), tz = "UTC"),
      # The other types come from a `schema` of dbSendQueryArrow()
      L = bit64::integer64(),
      nanoarrow::infer_nanoarrow_ptype(
        nanoarrow::nanoarrow_schema_modify(nanoarrow::na_na(), list(format = format))
      )
    )
    arrow_df_ptypes[[format]] <- ptype
  }
  ptype
}

# dbColumnInfo() through Arrow: the types of a fetch of no rows, named like
# the default path names them. Like the peek of the default path, the fetch
# reads the next row without converting it, and the next fetch starts from the
# types it decides. The columns of `ptype` are named after their prototype,
# which dbFetch() returns them as, whatever their Arrow format.
arrow_column_info <- function(res) {
  fetched <- result_fetch_arrow_df(res@ptr, 0, ARROW_DF_CHUNK_SIZE)
  formats <- fetched$formats
  type <- character(length(formats))
  requested <- match(names(res@ptype), fetched$names)
  type[requested] <- vapply(res@ptype, arrow_type_name, character(1), USE.NAMES = FALSE)
  for (j in setdiff(seq_along(formats), requested)) {
    type[[j]] <- switch(formats[[j]],
      n = "logical",
      # The default path names the type of storage of integer64
      l = if (fetched$wide_ints[[j]]) "double" else "integer",
      g = if (nzchar(fetched$seconds[[j]])) fetched$seconds[[j]] else "double",
      u = "character",
      z = "list",
      tdD = "Date",
      ttu = "hms",
      "tsu:UTC" = "POSIXct",
      stopc("Internal error: unexpected Arrow format ", formats[[j]])
    )
  }
  structure(
    list(name = fetched$names, type = type),
    row.names = .set_row_names(length(type)),
    class = "data.frame"
  )
}

# The type of an R vector as dbColumnInfo() names it: the class of an object
# such as a factor or a Date, the storage type of the others
arrow_type_name <- function(x) {
  if (is.object(x)) class(x)[[1L]] else typeof(x)
}

# dbAppendTable() through Arrow: the data frame is written as an Arrow stream
arrow_append_df <- function(conn, name, value) {
  value <- arrow_prepare_df(value)
  dbAppendTableArrow(conn, name, nanoarrow::as_nanoarrow_array_stream(value))
}

# What the default path does in sqlData() and dbBind() before writing:
# factors become strings, lists of raw vectors become blobs,
# and difftime, POSIXct and Date columns are written as their numbers
arrow_prepare_df <- function(value) {
  value <- factor_to_string(value, warn = TRUE)

  # A POSIXlt column is a list, which the default path can't bind:
  # it is written as POSIXct, before the check of the lists
  is_posixlt <- vlapply(value, inherits, "POSIXlt")
  value[is_posixlt] <- lapply(value[is_posixlt], as.POSIXct)

  is_list <- vlapply(value, function(x) is.list(x) && !is.data.frame(x) && !inherits(x, "blob"))
  value[is_list] <- lapply(value[is_list], function(x) {
    x <- unclass(x)
    if (!all(vlapply(x, function(elt) is.null(elt) || is.raw(elt)))) {
      stopc("Can only write lists of raw vectors (or NULL)")
    }
    blob::as_blob(x)
  })

  # nanoarrow would write a duration in seconds, and times, timestamps and
  # dates in whole units, microseconds or days
  is_number <- vlapply(value, inherits, c("difftime", "POSIXct", "Date"))
  value[is_number] <- lapply(value[is_number], as.numeric)

  value
}
