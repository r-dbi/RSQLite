#' Make R/S-Plus identifiers into legal SQL identifiers
#'
#' Deprecated. Please use [dbQuoteIdentifier()] instead.
#'
#' @keywords internal
#' @rdname keywords-dep
#' @usage NULL
make.db.names_SQLiteConnection_character <- function(dbObj, snames, keywords, unique, allow.keywords, ...) {
  warning_once("RSQLite::make.db.names() is deprecated, please switch to DBI::dbQuoteIdentifier().")
  make.db.names.default(snames, keywords, unique, allow.keywords)
}
#' @rdname keywords-dep
#' @export
setMethod("make.db.names", signature(dbObj = "SQLiteConnection", snames = "character"), make.db.names_SQLiteConnection_character)
