# The warning about the values of an Arrow chunk that didn't fit the type of
# their column, raised by result_fetch_arrow_chunk() once per chunk,
# after the chunk is complete: see SqliteResultImpl::fetch_arrow_chunk().
#
# `coercions` has one element for each column with such values,
# a list of its name as `column`, its Arrow type as `type`,
# and as `values` the groups of its values by storage class and reason:
# each a list of `class`, `reason`, `count`,
# and `rows`, the first row numbers in the result, counted from 1.
# The warning carries `coercions` in a field of the same name.
# The condition is built and signalled with base R:
# through rlang::warn(), the warning costs about eight times as much,
# which a stream of small chunks pays once per chunk.
warn_coercion <- function(coercions) {
  n <- length(coercions)
  header <- paste0(
    "Values converted to the Arrow type of ", n,
    if (n == 1) " column:" else " columns:"
  )
  bullets <- vapply(coercions, format_coercion_column, character(1))
  warning(structure(
    list(
      message = paste(c(header, paste0("* ", bullets)), collapse = "\n"),
      call = NULL,
      coercions = coercions
    ),
    class = c("RSQLite_warning_coercion", "warning", "condition")
  ))
}

format_coercion_column <- function(column) {
  values <- vapply(column$values, format_coercion_values, character(1))
  paste0(
    "Column `", column$column, "` (", column$type, "): ",
    paste(values, collapse = "; ")
  )
}

format_coercion_values <- function(values) {
  count <- values$count
  outcome <- switch(values$reason,
    converted = "converted",
    out_of_range = "out of range, NULL instead",
    invalid_utf8 = "not valid UTF-8 or with a NUL byte, NULL instead",
    unparsable = "not parsable, NULL instead",
    null_type = "dropped by the null type"
  )
  paste0(
    format_whole_number(count), " ", values$class,
    if (count == 1) " value " else " values ", outcome,
    " (", format_coercion_rows(count, values$rows), ")"
  )
}

# The first row numbers, followed by an ellipsis if there are more
format_coercion_rows <- function(count, rows) {
  rows <- format_whole_number(rows)
  label <- if (count == 1) "row " else "rows "
  n <- length(rows)
  if (count > n) {
    paste0(label, paste(c(rows, "..."), collapse = ", "))
  } else if (n <= 2) {
    paste0(label, paste(rows, collapse = " and "))
  } else {
    paste0(label, paste(rows[-n], collapse = ", "), ", and ", rows[[n]])
  }
}

# Counts and row numbers arrive as doubles, which format() prints
# as 1e+05 from 100000 on
format_whole_number <- function(x) {
  sprintf("%.0f", x)
}
