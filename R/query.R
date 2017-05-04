#' @include SQLiteResult.R
NULL

#' @rdname SQLiteConnection-class
#' @export
setMethod("dbSendQuery", c("SQLiteConnection", "character"),
  function(conn, statement, params = NULL, ...) {
    statement <- enc2utf8(statement)

    if (!is.null(conn@ref$result)) {
      warning("Closing open result set, pending rows", call. = FALSE)
      dbClearResult(conn@ref$result)
      stopifnot(is.null(conn@ref$result))
    }

    rs <- new("SQLiteResult",
      sql = statement,
      ptr = rsqlite_send_query(conn@ptr, statement),
      conn = conn
    )
    on.exit(dbClearResult(rs), add = TRUE)

    if (!is.null(params)) {
      dbBind(rs, params)
    }
    on.exit(NULL, add = FALSE)

    conn@ref$result <- rs
    rs
  }
)


#' @rdname SQLiteResult-class
#' @export
setMethod("dbBind", "SQLiteResult", function(res, params, ...) {
  db_bind(res, as.list(params), ..., allow_named_superset = FALSE)
})


db_bind <- function(res, params, ..., allow_named_superset) {
  if (is.null(names(params))) {
    names(params) <- rep("", length(params))
  } else if (allow_named_superset) {
    param_pos <- rsqlite_find_params(res@ptr, names(params))
    if (any(is.na(param_pos))) {
      warning("Named parameters not used in query: ",
              paste0(names(params)[is.na(param_pos)], collapse = ", "),
              ". Use $", names(params)[is.na(param_pos)][[1]],
              " etc. instead of ? with named lists.",
              call. = FALSE)
      params <- params[!is.na(param_pos)]
    }
  }

  params <- factor_to_string(params)
  params <- string_to_utf8(params)

  rsqlite_bind_rows(res@ptr, params)
  invisible(res)
}


#' @export
#' @rdname SQLiteResult-class
setMethod("dbFetch", "SQLiteResult", function(res, n = -1, ...,
                                              row.names = pkgconfig::get_config("RSQLite::row.names.query", FALSE)) {
  row.names <- compatRowNames(row.names)
  if (length(n) != 1) stopc("n must be scalar")
  if (n < -1) stopc("n must be nonnegative or -1")
  if (is.infinite(n)) n <- -1
  if (trunc(n) != n) stopc("n must be a whole number")
  sqlColumnToRownames(rsqlite_fetch(res@ptr, n = n), row.names)
})

#' @export
#' @rdname SQLiteResult-class
setMethod("dbClearResult", "SQLiteResult", function(res, ...) {
  if (!dbIsValid(res)) {
    stop("Expired, result set already closed", call. = FALSE)
  }
  rsqlite_clear_result(res@ptr)
  res@conn@ref$result <- NULL
  invisible(TRUE)
})

#' @export
#' @rdname SQLiteResult-class
setMethod("dbColumnInfo", "SQLiteResult", function(res, ...) {
  rsqlite_column_info(res@ptr)
})
#' @export
#' @rdname SQLiteResult-class
setMethod("dbGetRowsAffected", "SQLiteResult", function(res, ...) {
  rsqlite_rows_affected(res@ptr)
})
#' @export
#' @rdname SQLiteResult-class
setMethod("dbGetRowCount", "SQLiteResult", function(res, ...) {
  rsqlite_row_count(res@ptr)
})
#' @export
#' @rdname SQLiteResult-class
setMethod("dbHasCompleted", "SQLiteResult", function(res, ...) {
  rsqlite_has_completed(res@ptr)
})
#' @rdname SQLiteResult-class
#' @export
setMethod("dbGetStatement", "SQLiteResult", function(res, ...) {
  res@sql
})
