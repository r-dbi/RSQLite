# A string marked as UTF-8 from its bytes in hex, which may be invalid UTF-8
utf8_hex <- function(x) {
  out <- rawToChar(as.raw(strtoi(strsplit(x, " ")[[1]], 16L)))
  Encoding(out) <- "UTF-8"
  out
}

# A connection with check_utf8 and an optional database encoding,
# closed when the calling test finishes
local_utf8_check_con <- function(
  check_utf8 = TRUE,
  encoding = NULL,
  .env = parent.frame()
) {
  con <- dbConnect(SQLite(), check_utf8 = check_utf8)
  withr::defer(dbDisconnect(con), envir = .env)
  if (!is.null(encoding)) {
    dbExecute(con, paste0("PRAGMA encoding = '", encoding, "'"))
  }
  con
}

# A table `t` with one untyped column `x`, so that values keep their type
create_utf8_check_table <- function(con, values) {
  dbExecute(con, "CREATE TABLE t (x)")
  rows <- paste0("(", values, ")", collapse = ", ")
  dbExecute(con, paste("INSERT INTO t VALUES", rows))
}

# The value of `expr` and the messages of the warnings it raises
utf8_with_warnings <- function(expr) {
  messages <- character()
  value <- withCallingHandlers(
    expr,
    warning = function(w) {
      messages <<- c(messages, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = messages)
}

# Only the warnings of check_utf8, not the one about mixed types
utf8_warnings <- function(out) {
  grep("UTF-8", out$warnings, value = TRUE)
}

# The warning check_utf8 = TRUE gives for `n` invalid values in column `name`
utf8_invalid_message <- function(n, name = "x") {
  if (n == 1) {
    what <- "1 value is not valid UTF-8 or contains a NUL byte"
  } else {
    what <- paste(n, "values are not valid UTF-8 or contain NUL bytes")
  }
  paste0("Column `", name, "`: ", what, ", NA is returned")
}
