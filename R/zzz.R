.onLoad <- function(libname, pkgname) {
  warning_once <<- memoise::memoise(warning_once)
}

.onUnload <- function(libpath) {
  gc() # Force garbage collection of connections
  library.dynam.unload("RSQLite", libpath)
}
