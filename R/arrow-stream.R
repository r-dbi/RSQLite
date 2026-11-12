# The rows of `res` as a nanoarrow_array_stream that fetches them lazily:
# each get_next() returns the next chunk of at most `n` rows,
# all of them for -1, as result_fetch_arrow_chunk() builds it,
# with the warning about the values converted to the type of their column.
# get_schema() reads the first chunk, which decides the types,
# and keeps it for the first get_next().
# The stream reads on after `res` is cleared or its connection closed,
# and keeps the statement, and a closed connection, open until it has ended
# or is released.
# Once `res` is bound to new parameters,
# the stream fails with an error that says so.
# Internal for now: no DBI method calls it yet.
read_arrow_stream <- function(res, n = 65536L) {
  if (!is.numeric(n) || length(n) != 1 || is.na(n) ||
    !(n == -1 || (n >= 1 && n <= .Machine$integer.max && n == trunc(n)))) {
    rlang::abort("`n` must be a positive whole number, or -1 for all rows.")
  }
  claim_fetch_kind(res, "an Arrow stream")
  result_create_arrow_stream(res@ptr, as.integer(n))
}

# A result is fetched either as data frames or as an Arrow stream,
# whichever comes first, not both,
# until DBI says whether a backend must allow mixing (r-dbi/DBI#773).
# This is the one place of the rule: dropping the error allows mixing,
# which the result itself supports.
# `kind` reads "a data frame" or "an Arrow stream".
claim_fetch_kind <- function(res, kind) {
  claimed <- result_claim_fetch_kind(res@ptr, kind)
  if (claimed != kind) {
    rlang::abort(
      c(
        paste0(
          "Can't fetch a result as ", kind,
          " after fetching it as ", claimed, "."
        ),
        i = "Fetch each result in one way only, or send the query again."
      ),
      class = "RSQLite_error_fetch_kind",
      call = NULL
    )
  }
  invisible()
}
