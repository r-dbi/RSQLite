#' Copy a SQLite database
#' 
#' This function copies a database connection to a file or to another database
#' connection.It can be used to save an in-memory database (created using
#' \code{dbname = ":memory:"}) to a file or to create an in-memory database as
#' a copy of anothe database.
#' 
#' @param from A \code{SQLiteConnection} object. The main database in
#'   \code{from} will be copied to \code{to}.
#' @param to A \code{SQLiteConnection} object pointing to an empty database.
#' @return Returns \code{NULL} (invisibly).
#' @author Seth Falcon
#' @references \url{http://www.sqlite.org/backup.html}
#' @export
#' @examples
#' # Copy the built in databaseDb() to an in memory dataset
#' db <- dbConnect(RSQLite::SQLite(), ":memory:")
#' sqliteCopyDatabase(datasetsDb(), db)
#' dbListTables(db)
sqliteCopyDatabase <- function(from, to) {
  if (!is(from, "SQLiteConnection"))
    stop("'from' must be a SQLiteConnection object")
  if (!is(to, "SQLiteConnection"))
    stop("'to' must be a SQLiteConnection object")
  
  rsqlite_copy_database(from@ptr, to@ptr)
  invisible(NULL)
}
