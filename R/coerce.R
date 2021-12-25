sql_data <- function(value, row.names) {
  row.names <- compatRowNames(row.names)
  value <- sqlRownamesToColumn(value, row.names)

  value <- factor_to_string(value)
  value <- raw_to_string(value)
  value <- string_to_utf8(value)
  value
}

factor_to_string <- function(value, warn = FALSE) {
  is_factor <- vlapply(value, is.factor)
  if (warn && any(is_factor)) {
    warning("Factors converted to character", call. = FALSE)
  }
  value[is_factor] <- lapply(value[is_factor], as.character)
  value
}

raw_to_string <- function(value) {
  is_raw <- vlapply(value, is.raw)

  if (any(is_raw)) {
    warning("Creating a TEXT column from raw, use lists of raw to create BLOB columns", call. = FALSE)
    value[is_raw] <- lapply(value[is_raw], as.character)
  }

  value
}

quote_string <- function(value, conn) {
  is_character <- vlapply(value, is.character)
  value[is_character] <- lapply(value[is_character], dbQuoteString, conn = conn)
  value
}

string_to_utf8 <- function(value) {
  is_char <- vlapply(value, is.character)
  value[is_char] <- lapply(value[is_char], enc2utf8)
  value
}
