#' Copy a SQLite database
#'
#' Copies a database connection to a file or to another database
#' connection.  It can be used to save an in-memory database (created using
#' `dbname = ":memory:"` or
#' `dbname = "file::memory:"`) to a file or to create an in-memory database
#' a copy of another database.
#'
#' @param from A `SQLiteConnection` object. The main database in
#'   `from` will be copied to `to`.
#' @param to A `SQLiteConnection` object pointing to an empty database.
#' @author Seth Falcon
#' @references \url{http://www.sqlite.org/backup.html}
#' @export
#' @examples
#' library(DBI)
#' # Copy the built in databaseDb() to an in-memory database
#' con <- dbConnect(RSQLite::SQLite(), ":memory:")
#' dbListTables(con)
#'
#' db <- RSQLite::datasetsDb()
#' RSQLite::sqliteCopyDatabase(db, con)
#' dbDisconnect(db)
#' dbListTables(con)
#'
#' dbDisconnect(con)
sqliteCopyDatabase <- function(from, to) {
  if (!is(from, "SQLiteConnection"))
    stop("'from' must be a SQLiteConnection object")
  if (is.character(to)) {
    to <- dbConnect(SQLite(), to)
    on.exit(dbDisconnect(to), add = TRUE)
  }
  if (!is(to, "SQLiteConnection"))
    stop("'to' must be a SQLiteConnection object")

  connection_copy_database(from@ptr, to@ptr)
  invisible(NULL)
}
