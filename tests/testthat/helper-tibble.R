list_df <- function(...) {
  df <- list(...)
  if (length(df) > 0)
    attr(df, "row.names") <- .set_row_names(length(df[[1]]))
  else
    attr(df, "row.names") <- .set_row_names(0L)
  class(df) <- "data.frame"
  df
}
