# The reference for utf8_valid(), from base R.
# rawToChar() drops trailing NUL bytes and refuses inner ones,
# so the NUL check comes first.
utf8_reference <- function(x) {
  vapply(
    x,
    function(bytes) !any(bytes == as.raw(0)) && validUTF8(rawToChar(bytes)),
    logical(1),
    USE.NAMES = FALSE
  )
}

# Raw vectors from strings of hex bytes separated by spaces, one per string
raw_hex <- function(...) {
  lapply(c(...), function(x) as.raw(strtoi(strsplit(x, " ")[[1]], 16L)))
}

# `n` ASCII bytes, as padding that is valid UTF-8
raw_ascii <- function(n) {
  as.raw(rep_len(0x61:0x7a, n))
}

# Each byte string with `k` ASCII bytes in front and behind, for every `k`
# that moves it across the boundary of an eight-byte word
raw_pad <- function(x, k = 0:17) {
  unlist(
    lapply(k, function(k) {
      lapply(x, function(bytes) c(raw_ascii(k), bytes, raw_ascii(k)))
    }),
    recursive = FALSE
  )
}

# Expects utf8_valid() and utf8_reference() to give `expected`
# for every byte string, and utf8_valid() also after raw_pad()
expect_utf8 <- function(x, expected) {
  expect_identical(utf8_reference(x), rep(expected, length(x)))
  expect_identical(utf8_valid(x), rep(expected, length(x)))
  padded <- raw_pad(x)
  expect_identical(utf8_valid(padded), rep(expected, length(padded)))
}
