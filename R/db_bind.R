#' @include SQLiteResult.R
NULL

db_bind <- function(res, params, ..., allow_named_superset) {
  placeholder_names <- result_get_placeholder_names(res@ptr)

  if (is_unnamed_placeholders(placeholder_names)) {
    if (!is.null(names(params)) || any(names(params) != "")) {
      stopc("Cannot use named parameters for anonymous/numbered placeholders")
    }
  } else {
    param_indexes <- match_placeholders(
      placeholder_names,
      params,
      allow_named_superset
    )
    params <- unname(params[param_indexes])
  }

  params <- factor_to_string(params, warn = TRUE)
  params <- string_to_utf8(params)

  result_bind(res@ptr, params)
  invisible(res)
}

# Binds the rows of `stream`, a nanoarrow_array_stream of struct arrays
# or an object that nanoarrow converts to one, such as a data frame,
# as dbBind() binds the rows of a data frame:
# the statement runs once per row.
# Named placeholders take the columns of the same name,
# anonymous and numbered ones take unnamed columns by position.
# A dictionary, such as a factor, binds its values.
# Types that SQLite can't store,
# and a stream that reads the rows of `res`,
# also through the parameters of other results,
# fail before any row runs,
# and leave `stream` and the previous bind as they were;
# otherwise the result takes the stream over and reads its arrays as it runs.
# Internal for now: no DBI method calls it yet.
bind_arrow_stream <- function(res, stream) {
  stream <- nanoarrow::as_nanoarrow_array_stream(stream)
  # Before the schema, whose read fetches the rows of a stream of RSQLite
  result_check_arrow_params(res@ptr, stream)
  schema <- nanoarrow::infer_nanoarrow_schema(stream)
  if (!identical(schema$format, "+s")) {
    stopc(
      "Parameters must be an Arrow stream of struct arrays, ",
      "with a column per placeholder."
    )
  }
  children <- schema$children
  placeholder_names <- result_get_placeholder_names(res@ptr)

  if (is_unnamed_placeholders(placeholder_names)) {
    if (any(names(children) != "")) {
      stopc("Cannot use named parameters for anonymous/numbered placeholders")
    }
    param_indexes <- seq_along(children)
  } else {
    param_indexes <- match_placeholders(
      placeholder_names,
      children,
      allow_named_superset = FALSE
    )
  }

  result_bind_arrow_stream(res@ptr, stream, param_indexes - 1L)
  invisible(res)
}

is_unnamed_placeholders <- function(placeholder_names) {
  empty <- placeholder_names == ""
  numbers <- grepl("^[1-9][0-9]*$", placeholder_names)

  if (any(empty) && !all(empty)) {
    stopc("Cannot mix anonymous and named/numbered placeholders in query")
  }

  if (any(numbers) && !all(numbers)) {
    stopc("Cannot mix numbered and named placeholders in query")
  }

  any(empty) || any(numbers)
}

# The position of each placeholder among the elements of `params`, by name.
# `params` is any vector or list whose names are matched,
# such as a list of parameters or the named `children` of an Arrow schema,
# not a vector of the names themselves.
# An element that no placeholder uses, such as any element of an unnamed list,
# is an error, or a warning with `allow_named_superset`.
match_placeholders <- function(
  placeholder_names,
  params,
  allow_named_superset
) {
  param_names <- names(params)
  param_indexes <- match(placeholder_names, param_names)
  if (any(is.na(param_indexes))) {
    stopc(
      "No value given for placeholder ",
      paste0(placeholder_names[is.na(param_indexes)], collapse = ", ")
    )
  }
  unmatched_param_indexes <- setdiff(seq_along(params), param_indexes)
  if (length(unmatched_param_indexes) > 0L) {
    if (allow_named_superset) {
      errorc <- warningc
    } else {
      errorc <- stopc
    }

    errorc(
      "Named parameters not used in query: ",
      paste0(param_names[unmatched_param_indexes], collapse = ", ")
    )
  }

  param_indexes
}

convert_bigint <- function(df, bigint) {
  if (bigint == "integer64") {
    return(df)
  }
  is_int64 <- which(vlapply(df, inherits, "integer64"))
  if (length(is_int64) == 0) {
    return(df)
  }

  as_bigint <- switch(bigint,
    integer = as.integer,
    numeric = as.numeric,
    character = as.character
  )

  df[is_int64] <- suppressWarnings(lapply(df[is_int64], as_bigint))
  df
}
