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
      ptr = result_create(conn@ptr, statement),
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
  placeholder_names <- result_get_placeholder_names(res@ptr)
  empty <- placeholder_names == ""
  numbers <- grepl("^[1-9][0-9]*$", placeholder_names)
  names <- !(empty | numbers)

  if (any(empty) && !all(empty)) {
    stopc("Cannot mix anonymous and named/numbered placeholders in query")
  }

  if (any(numbers) && !all(numbers)) {
    stopc("Cannot mix numbered and named placeholders in query")
  }

  if (any(empty) || any(numbers)) {
    if (!is.null(names(params))) {
      stopc("Cannot use named parameters for anonymous/numbered placeholders")
    }
  } else {
    param_indexes <- match(placeholder_names, names(params))
    if (any(is.na(param_indexes))) {
      stopc(
        "No value given for placeholder ",
        paste0(placeholder_names[is.na(param_indexes)], collapse = ", ")
      )
    }
    unmatched_param_indexes <- setdiff(seq_along(params), param_indexes)
    if (length(unmatched_param_indexes) > 0L) {
      if (allow_named_superset) errorc <- warningc
      else errorc <- stopc

      errorc(
        "Named parameters not used in query: ",
        paste0(names(params)[unmatched_param_indexes], collapse = ", ")
      )
    }

    params <- unname(params[param_indexes])
  }

  params <- factor_to_string(params, warn = TRUE)
  params <- string_to_utf8(params)

  result_bind(res@ptr, params)
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
  sqlColumnToRownames(result_fetch(res@ptr, n = n), row.names)
})

#' @export
#' @rdname SQLiteResult-class
setMethod("dbClearResult", "SQLiteResult", function(res, ...) {
  if (!dbIsValid(res)) {
    warningc("Expired, result set already closed")
    return(invisible(TRUE))
  }
  result_release(res@ptr)
  res@conn@ref$result <- NULL
  invisible(TRUE)
})

#' @export
#' @rdname SQLiteResult-class
setMethod("dbColumnInfo", "SQLiteResult", function(res, ...) {
  result_column_info(res@ptr)
})
#' @export
#' @rdname SQLiteResult-class
setMethod("dbGetRowsAffected", "SQLiteResult", function(res, ...) {
  result_rows_affected(res@ptr)
})
#' @export
#' @rdname SQLiteResult-class
setMethod("dbGetRowCount", "SQLiteResult", function(res, ...) {
  result_rows_fetched(res@ptr)
})
#' @export
#' @rdname SQLiteResult-class
setMethod("dbHasCompleted", "SQLiteResult", function(res, ...) {
  result_has_completed(res@ptr)
})
#' @rdname SQLiteResult-class
#' @export
setMethod("dbGetStatement", "SQLiteResult", function(res, ...) {
  if (!dbIsValid(res)) {
    stopc("Expired, result set already closed")
  }
  res@sql
})
