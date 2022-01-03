#' @include SQLiteConnection.R
#' @rdname keywords-dep
#' @usage NULL
SQLKeywords_SQLiteConnection <- function(dbObj, ...) {
  .SQL92Keywords
}
#' @rdname keywords-dep
#' @export
setMethod("SQLKeywords", "SQLiteConnection", SQLKeywords_SQLiteConnection)
