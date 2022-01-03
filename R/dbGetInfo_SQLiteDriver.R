#' @rdname SQLiteDriver-class
#' @usage NULL
dbGetInfo_SQLiteDriver <- function(dbObj, ...) {
  version <- RSQLite::rsqliteVersion()
  list(
    driver.version = PACKAGE_VERSION,
    client.version = package_version(version[[2]])
  )
}
#' @rdname SQLiteDriver-class
#' @export
setMethod("dbGetInfo", "SQLiteDriver", dbGetInfo_SQLiteDriver)
