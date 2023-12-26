#' @include SQLiteResult.R
NULL

db_bind <- function(res, params, ..., allow_named_superset) {
  placeholder_names <- result_get_placeholder_names(res@ptr)
  empty <- placeholder_names == ""
  numbers <- grepl("^[1-9][0-9]*$", placeholder_names)
  names <- !(empty | numbers)

  if (any(empty) && !all(empty)) {
    stopc("Cannot mix anonymous and named/numbered placeholders in query")
  }

  if (any(numbers) && !all(numbers)) {
    stopc("Cannot mix numbered and named placeholders in query")
  }

  if (any(empty) || any(numbers)) {
    if (!is.null(names(params)) || any(names(params) != "")) {
      stopc("Cannot use named parameters for anonymous/numbered placeholders")
    }
  } else {
    param_indexes <- match(placeholder_names, names(params))
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
        paste0(names(params)[unmatched_param_indexes], collapse = ", ")
      )
    }

    params <- unname(params[param_indexes])
  }

  params <- factor_to_string(params, warn = TRUE)
  params <- string_to_utf8(params)

  result_bind(res@ptr, params)
  invisible(res)
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
