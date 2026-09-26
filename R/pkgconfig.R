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
    "RSQLite: Setting the default for `row.names` via `pkgconfig::set_config(\"", key, "\" = ...)`, ",
    "in your code or in a package you use, is deprecated and will be ignored in a future version. ",
    "Remove the `pkgconfig::set_config()` call and pass `row.names = ", deparse(value), "` explicitly instead."
  )
  value
}
