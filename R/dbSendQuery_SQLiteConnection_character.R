#' @rdname SQLiteConnection-class
#' @param ptype The R types of some or all result columns,
#'   as a data frame or a named list of vectors whose values are ignored,
#'   such as `list(id = bit64::integer64(), when = as.POSIXct(character(), tz = "UTC"))`,
#'   matched to the result columns by name.
#'   Requires a connection with `arrow = TRUE`, see the section on data frames in [sqlite-arrow].
#'   The default `NULL` decides the types from the values.
#' @usage NULL
dbSendQuery_SQLiteConnection_character <- function(conn, statement, params = NULL, ..., ptype = NULL) {
  statement <- enc2utf8(statement)

  if (!is.null(ptype)) {
    if (!conn@arrow) {
      stopc("`ptype` requires a connection with `arrow = TRUE`")
    }
    ptype <- arrow_check_ptype(ptype)
  }

  if (!is.null(conn@ref$result)) {
    warning("Closing open result set, pending rows", call. = FALSE)
    dbClearResult(conn@ref$result)
    stopifnot(is.null(conn@ref$result))
  }

  rs <- new("SQLiteResult",
    sql = statement,
    ptr = result_create(conn@ptr, statement),
    conn = conn,
    bigint = conn@bigint,
    ptype = ptype
  )
  on.exit(dbClearResult(rs), add = TRUE)

  if (!is.null(ptype)) {
    arrow_set_schema(rs, arrow_ptype_schema(ptype), arg = "ptype")
  }

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
