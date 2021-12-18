#' @rdname SQLiteConnection-class
#' @usage NULL
dbGetInfo_SQLiteConnection <- function(dbObj, ...) {
  version <- RSQLite::rsqliteVersion()

  list(
    db.version = version[[2]],
    dbname = dbObj@dbname,
    username = NA,
    host = NA,
    port = NA
  )
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbGetInfo", "SQLiteConnection", dbGetInfo_SQLiteConnection)
