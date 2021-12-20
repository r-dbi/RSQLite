# dbDisconnect()
# dbSendQuery()
# dbSendStatement()
# dbDataType()
# dbQuoteString()
# dbQuoteIdentifier()
#' @rdname SQLiteConnection-class
#' @usage NULL
dbQuoteIdentifier_SQLiteConnection_character <- function(conn, x, ...) {
  if (any(is.na(x))) {
    stop("Cannot pass NA to dbQuoteIdentifier()", call. = FALSE)
  }
  # Avoid fixed = TRUE due to https://github.com/r-dbi/DBItest/issues/156
  x <- gsub("`", "``", enc2utf8(x))
  if (length(x) == 0L) {
    SQL(character(), names = names(x))
  } else {
    # Not calling encodeString() here to keep things simple
    SQL(paste("`", x, "`", sep = ""), names = names(x))
  }
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbQuoteIdentifier", c("SQLiteConnection", "character"), dbQuoteIdentifier_SQLiteConnection_character)
