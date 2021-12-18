#' Read a database table
#'
#' Returns the contents of a database table given by name as a data frame.
#'
#' Note that the data frame returned by `dbReadTable()` only has
#' primitive data, e.g., it does not coerce character data to factors.
#'
#' @seealso
#' The corresponding generic function [DBI::dbReadTable()].
#'
#' @return A data frame.
#'
#' @param conn a \code{\linkS4class{SQLiteConnection}} object, produced by
#'   [DBI::dbConnect()]
#' @param name a character string specifying a table name. SQLite table names
#'   are \emph{not} case sensitive, e.g., table names `ABC` and `abc`
#'   are considered equal.
#' @param check.names If `TRUE`, the default, column names will be
#'   converted to valid R identifiers.
#' @param select.cols  Deprecated, do not use.
#' @param ... Needed for compatibility with generic. Otherwise ignored.
#' @inheritParams DBI::sqlRownamesToColumn
#' @examples
#' library(DBI)
#' db <- RSQLite::datasetsDb()
#' dbReadTable(db, "mtcars")
#' dbReadTable(db, "mtcars", row.names = FALSE)
#' dbDisconnect(db)
#' @usage NULL
dbReadTable_SQLiteConnection_character <- function(conn, name, ...,
                                                   row.names = pkgconfig::get_config("RSQLite::row.names.table", FALSE),
                                                   check.names = TRUE, select.cols = NULL) {
  name <- check_quoted_identifier(name)

  row.names <- compatRowNames(row.names)

  if ((!is.logical(row.names) && !is.character(row.names)) || length(row.names) != 1L) {
    stopc("`row.names` must be a logical scalar or a string")
  }

  if (!is.logical(check.names) || length(check.names) != 1L) {
    stopc("`check.names` must be a logical scalar")
  }

  if (is.null(select.cols)) {
    select.cols <- "*"
  } else {
    warning_once("`select.cols` is deprecated, use `dbGetQuery()` for complex queries.",
      call. = FALSE
    )
  }

  name <- dbQuoteIdentifier(conn, name)
  out <- dbGetQuery(conn, paste("SELECT", select.cols, "FROM", name),
    row.names = row.names
  )

  if (check.names) {
    names(out) <- make.names(names(out), unique = TRUE)
  }

  out
}

#' @export
setMethod("dbReadTable", c("SQLiteConnection", "character"), dbReadTable_SQLiteConnection_character)
