# The operating system: "windows", "osx" or "unix"
os <- function() {
  ostype <- .Platform[["OS.type"]]
  if (ostype == "windows") {
    return("windows")
  }
  if (grepl("darwin", R.Version()$os)) {
    return("osx")
  }
  ostype
}
