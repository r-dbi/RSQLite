compatRowNames <- function(row.names) {
  if (is.numeric(row.names)) {
    warning("Passing numeric values to row.names is deprecated. Pass a logical or a column name.",
            call. = FALSE)
    row.names <- as.logical(row.names)
  }

  row.names
}
