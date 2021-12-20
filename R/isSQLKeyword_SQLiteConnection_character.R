#' @rdname keywords-dep
#' @usage NULL
isSQLKeyword_SQLiteConnection_character <- function(dbObj, name, keywords, case, ...) {
  warning_once("RSQLite::isSQLKeyword() is deprecated, please switch to DBI::dbQuoteIdentifier().")
  isSQLKeyword.default(name, keywords = .SQL92Keywords, case)
}
#' @rdname keywords-dep
#' @export
setMethod("isSQLKeyword", signature(dbObj = "SQLiteConnection", name = "character"), isSQLKeyword_SQLiteConnection_character)
