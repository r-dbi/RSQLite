# utf8_valid() exposes rsqlite_is_utf8_string() from src/utf8.cpp for testing.
# The reference is base R:
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

hex <- function(...) {
  lapply(c(...), function(x) as.raw(strtoi(strsplit(x, " ")[[1]], 16L)))
}

ascii <- function(n) {
  as.raw(rep_len(0x61:0x7a, n))
}

# Each byte string with `k` ASCII bytes in front and behind, for every `k`
# that moves it across the boundary of an eight-byte word
pad <- function(x, k = 0:17) {
  unlist(
    lapply(k, function(k) {
      lapply(x, function(bytes) c(ascii(k), bytes, ascii(k)))
    }),
    recursive = FALSE
  )
}

expect_utf8 <- function(x, expected) {
  expect_identical(utf8_reference(x), rep(expected, length(x)))
  expect_identical(utf8_valid(x), rep(expected, length(x)))
  padded <- pad(x)
  expect_identical(utf8_valid(padded), rep(expected, length(padded)))
}

test_that("the boundaries of every sequence length are valid", {
  expect_utf8(
    hex(
      "01",
      "7f",
      "c2 80",
      "df bf",
      "e0 a0 80",
      "ed 9f bf",
      "ee 80 80",
      "ef bf bf",
      "f0 90 80 80",
      "f4 8f bf bf"
    ),
    TRUE
  )
})

test_that("overlong forms are invalid", {
  expect_utf8(
    hex(
      "c0 80",
      "c0 af",
      "c1 bf",
      "e0 80 80",
      "e0 9f bf",
      "f0 80 80 80",
      "f0 8f bf bf"
    ),
    FALSE
  )
})

test_that("surrogates are invalid", {
  expect_utf8(hex("ed a0 80", "ed af bf", "ed b0 80", "ed bf bf"), FALSE)
})

test_that("code points beyond U+10FFFF and bytes outside UTF-8 are invalid", {
  expect_utf8(
    hex(
      "f4 90 80 80",
      "f4 bf bf bf",
      "f5 80 80 80",
      "f7 bf bf bf",
      "f8 88 80 80 80",
      "fc 84 80 80 80 80",
      "fe",
      "ff"
    ),
    FALSE
  )
})

test_that("truncated sequences at the end are invalid", {
  expect_utf8(
    hex("c2", "df", "e0 a0", "ef bf", "f0 90", "f0 90 80", "f4 8f bf"),
    FALSE
  )
  # Without padding behind
  x <- lapply(hex("c2", "e2 82", "f0 9f 98"), function(bytes) {
    c(ascii(13), bytes)
  })
  expect_identical(utf8_valid(x), rep(FALSE, 3))
  expect_identical(utf8_reference(x), rep(FALSE, 3))
})

test_that("stray and missing continuation bytes are invalid", {
  expect_utf8(
    hex(
      "80",
      "bf",
      "61 80 62",
      "c2 80 80",
      "e2 82 ac 80",
      "c2 41",
      "e2 41 ac",
      "e2 82 41",
      "f0 9f 41 80",
      "f0 9f 98 41",
      "c2 c2 80"
    ),
    FALSE
  )
})

test_that("NUL bytes are invalid, at every position in and after a word", {
  x <- unlist(
    lapply(1:20, function(n) {
      lapply(seq_len(n), function(i) {
        bytes <- ascii(n)
        bytes[[i]] <- as.raw(0)
        bytes
      })
    }),
    recursive = FALSE
  )
  expect_identical(utf8_reference(x), rep(FALSE, length(x)))
  expect_identical(utf8_valid(x), rep(FALSE, length(x)))

  expect_utf8(hex("00", "c3 a4 00", "00 c3 a4", "e2 82 ac 00 61"), FALSE)
})

test_that("empty input and pure ASCII of any length are valid", {
  expect_identical(utf8_valid(list(raw())), TRUE)
  x <- lapply(0:40, ascii)
  expect_identical(utf8_valid(x), rep(TRUE, length(x)))
})

test_that("all one- and two-byte strings agree with base R", {
  x <- c(
    lapply(0:255, as.raw),
    lapply(0:65535, function(i) as.raw(c(i %/% 256, i %% 256)))
  )
  expect_identical(utf8_valid(x), utf8_reference(x))
  # Padding moves them into the word-at-a-time path
  x <- lapply(x, function(bytes) c(ascii(7), bytes))
  expect_identical(utf8_valid(x), utf8_reference(x))
})

test_that("three- and four-byte strings around the boundaries agree with base R", {
  edges <- hex("00 41 7f 80 8f 90 9f a0 bf c0 ff")[[1]]
  grid3 <- expand.grid(a = as.raw(0xc0:0xff), b = edges, c = edges)
  x <- .mapply(function(a, b, c) c(a, b, c), grid3, NULL)
  expect_identical(utf8_valid(x), utf8_reference(x))

  grid4 <- expand.grid(a = as.raw(0xe0:0xff), b = edges, c = edges, d = edges)
  x <- .mapply(function(a, b, c, d) c(a, b, c, d), grid4, NULL)
  expect_identical(utf8_valid(x), utf8_reference(x))
  x <- pad(x, 6)
  expect_identical(utf8_valid(x), utf8_reference(x))
})

test_that("random byte strings agree with base R", {
  withr::local_seed(20261111)

  # Mostly ASCII, with lead and continuation bytes, so that valid strings occur
  bytes <- as.raw(c(0x00, 0x20:0x7e, 0x80:0xbf))
  pool <- c(bytes, hex("c2 c3 e2 ed f0 f4 ff")[[1]])
  prob <- c(1, rep(30, 95), rep(2, 64), 5, 5, 5, 2, 3, 2, 1)
  x <- lapply(
    sample(0:40, 20000, replace = TRUE),
    function(n) sample(pool, n, replace = TRUE, prob = prob)
  )
  expect_identical(utf8_valid(x), utf8_reference(x))

  # Valid text with one byte changed
  chars <- intToUtf8(c(0x61, 0xe4, 0x20ac, 0x1f600, 0x7a), multiple = TRUE)
  x <- lapply(1:5000, function(i) {
    bytes <- charToRaw(paste(
      sample(chars, sample(1:12, 1), replace = TRUE),
      collapse = ""
    ))
    bytes[[sample(length(bytes), 1)]] <- as.raw(sample(0:255, 1))
    bytes
  })
  expect_true(any(utf8_valid(x)))
  expect_false(all(utf8_valid(x)))
  expect_identical(utf8_valid(x), utf8_reference(x))
})

test_that("non-raw input is an error", {
  expect_error(utf8_valid(list("a")), "expected 'raw'")
})
