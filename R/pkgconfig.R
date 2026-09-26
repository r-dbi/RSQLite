# Setting the default for `row.names` via `pkgconfig::set_config()` (#210) is deprecated.
# pkgconfig is consulted only if it is already loaded,
# which it is for anyone who has called `pkgconfig::set_config()`.
row_names_default <- function(key) {
  if (!isNamespaceLoaded("pkgconfig")) {
    return(FALSE)
  }

  value <- pkgconfig::get_config(key)
  if (is.null(value)) {
    return(FALSE)
  }

  warning_once(
    "RSQLite: Setting the default for `row.names` via `pkgconfig::set_config(\"", key, "\" = ...)` is deprecated ",
    "and will be ignored in a future version. ",
    "Pass `row.names = ", deparse(value), "` explicitly instead."
  )
  value
}
