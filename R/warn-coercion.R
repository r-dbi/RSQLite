# The warning for values that were not of the type of their column.
#
# The C++ code logs such values per column and chunk (see CoercionLog) and
# calls warn_coercion() once per fetched chunk with the entries:
# a list with one element per column, each a list with the column name,
# its Arrow type and the values grouped by storage class and reason,
# with their 1-based row numbers in the result.

# Whether cli is available for formatting, checked once per session
has_cli <- local({
  installed <- NULL
  function() {
    if (is.null(installed)) {
      installed <<- rlang::is_installed("cli")
    }
    installed
  }
})

warn_coercion <- function(entries) {
  if (has_cli()) {
    # Bullets are formatted by cli, the messages are used verbatim
    rlang::local_use_cli(format = TRUE, inline = FALSE)
  }

  n <- length(entries)
  header <- paste0(
    "Mixed types in ", n, if (n == 1) " column" else " columns",
    ", values converted to the column ", if (n == 1) "type" else "types", ":"
  )
  bullets <- vapply(entries, format_coercion_entry, character(1))

  rlang::warn(
    c(header, rlang::set_names(bullets, "*")),
    class = "RSQLite_warning_coercion",
    coercions = entries,
    call = NULL
  )
}

format_coercion_entry <- function(entry) {
  values <- vapply(entry$values, format_coercion_values, character(1))
  paste0(
    "Column `", entry$column, "` (", entry$type, "): ",
    paste(values, collapse = "; ")
  )
}

format_coercion_values <- function(values) {
  n <- values$count
  what <- paste0(n, " ", values$class, if (n == 1) " value" else " values")
  outcome <- switch(values$reason,
    converted = "converted",
    invalid_utf8 = "not valid UTF-8, NA",
    unparsable = "not in the expected format, NA",
    out_of_range = "out of range, NA",
    values$reason
  )
  paste0(what, " ", outcome, " (", format_coercion_rows(values), ")")
}

# The row numbers, truncated like cli does it: the first rows, an ellipsis,
# and the last two
format_coercion_rows <- function(values) {
  rows <- values$rows
  last <- values$last
  label <- if (values$count == 1) "row " else "rows "
  if (is.null(last)) {
    return(paste0(label, collapse_rows(rows)))
  }
  paste0(
    label,
    paste(rows[seq_len(min(length(rows), 18L))], collapse = ", "),
    ", ", ellipsis(), ", ",
    last[[1]], ", and ", last[[2]]
  )
}

collapse_rows <- function(x) {
  if (has_cli()) {
    return(cli::ansi_collapse(x))
  }
  n <- length(x)
  if (n <= 1) {
    paste(x)
  } else if (n == 2) {
    paste(x, collapse = " and ")
  } else {
    paste0(paste(x[-n], collapse = ", "), ", and ", x[n])
  }
}

ellipsis <- function() {
  if (has_cli()) cli::symbol$ellipsis else "..."
}
