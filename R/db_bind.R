#' @include SQLiteResult.R
NULL

db_bind <- function(res, params, ..., allow_named_superset) {
  placeholder_names <- result_get_placeholder_names(res@ptr)

  if (is_unnamed_placeholders(placeholder_names)) {
    if (!is.null(names(params)) || any(names(params) != "")) {
      stopc("Cannot use named parameters for anonymous/numbered placeholders")
    }
  } else {
    param_indexes <- match_placeholders(placeholder_names, names(params), allow_named_superset)
    params <- unname(params[param_indexes])
  }

  params <- factor_to_string(params, warn = TRUE)
  params <- string_to_utf8(params)

  result_bind(res@ptr, params)
  invisible(res)
}

# Binds the rows of a nanoarrow array stream, matching named placeholders to
# the names of the columns; the stream is consumed
db_bind_arrow <- function(res, stream) {
  placeholder_names <- result_get_placeholder_names(res@ptr)
  if (length(placeholder_names) == 0L) {
    stopc("Query does not require parameters.")
  }
  schema <- nanoarrow::infer_nanoarrow_schema(stream)
  if (!identical(schema$format, "+s")) {
    stopc("`params` must be a stream of struct arrays with one column per placeholder")
  }
  column_names <- arrow_schema_names(schema)

  if (is_unnamed_placeholders(placeholder_names)) {
    if (any(column_names != "")) {
      stopc("Cannot use named parameters for anonymous/numbered placeholders")
    }
    param_indexes <- seq_along(column_names)
  } else {
    param_indexes <- match_placeholders(placeholder_names, column_names, allow_named_superset = FALSE)
  }

  result_bind_arrow(res@ptr, stream, param_indexes - 1L)
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

# The position of each placeholder among the named parameters
match_placeholders <- function(placeholder_names, param_names, allow_named_superset) {
  param_indexes <- match(placeholder_names, param_names)
  if (any(is.na(param_indexes))) {
    stopc(
      "No value given for placeholder ",
      paste0(placeholder_names[is.na(param_indexes)], collapse = ", ")
    )
  }
  unmatched_param_indexes <- setdiff(seq_along(param_names), param_indexes)
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
