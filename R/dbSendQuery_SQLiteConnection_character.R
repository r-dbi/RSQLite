#' @rdname SQLiteConnection-class
#' @usage NULL
dbSendQuery_SQLiteConnection_character <- function(conn, statement, params = NULL, ...) {
  statement <- enc2utf8(statement)

  if (!is.null(conn@ref$result)) {
    warning("Closing open result set, pending rows", call. = FALSE)
    dbClearResult(conn@ref$result)
    stopifnot(is.null(conn@ref$result))
  }

  rs <- new("SQLiteResult",
    sql = statement,
    ptr = result_create(conn@ptr, statement),
    conn = conn,
    bigint = conn@bigint
  )
  on.exit(dbClearResult(rs), add = TRUE)

  if (!is.null(params)) {
    dbBind(rs, params)
  }
  on.exit(NULL, add = FALSE)

  conn@ref$result <- rs
  rs
}
#' @rdname SQLiteConnection-class
#' @export
setMethod("dbSendQuery", c("SQLiteConnection", "character"), dbSendQuery_SQLiteConnection_character)
