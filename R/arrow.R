#' Arrow support
#'
#' @description
#' RSQLite implements the Arrow interface of DBI natively.
#' [DBI::dbSendQueryArrow()], [DBI::dbFetchArrow()], [DBI::dbFetchArrowChunk()],
#' [DBI::dbGetQueryArrow()] and [DBI::dbReadTableArrow()] fill nanoarrow objects
#' straight from the SQLite statement,
#' and [DBI::dbBindArrow()], [DBI::dbAppendTableArrow()], [DBI::dbWriteTableArrow()]
#' and [DBI::dbCreateTableArrow()] bind Arrow arrays straight to statement parameters.
#' R vectors are never an intermediate step,
#' and a result set is never held in memory as a whole: see the section on chunking.
#'
#' @section Result columns:
#' SQLite is dynamically typed, so the Arrow type of a result column is decided from the values:
#' the first value that is not `NULL` decides,
#' and integers are widened to `double` if a real number turns up in the first chunk.
#' A column whose first chunk holds only `NULL` values takes the type of its declaration,
#' and a column without a declaration that only ever holds `NULL` is of the Arrow null type.
#' Once the first chunk has been fetched the types are fixed;
#' later values of another storage class are converted by SQLite's own rules,
#' with one warning per column.
#' Text and blobs in a `utf8` column must be valid UTF-8 without NUL bytes,
#' which SQLite does not enforce: other values become `NULL` with a warning,
#' where the data frame path passes text through unchecked.
#' The types can therefore depend on `chunk_size`:
#' a real number in a later chunk is truncated to fit an `int64` column decided from integers,
#' and a column whose first chunk holds only `NULL` keeps its declared type,
#' or the null type without a declaration, for the whole result.
#' The default chunk size makes this rare, a small `chunk_size` makes it likely.
#'
#' | *SQLite value or declared type* | *Arrow type* |
#' | ------------------------------- | ------------ |
#' | integer, or INTEGER affinity | `int64` |
#' | real, or REAL and NUMERIC affinity | `double` |
#' | text, or TEXT affinity | `utf8` |
#' | blob, or BLOB affinity | `binary` |
#' | `DATE` with `extended_types = TRUE` | `date32` |
#' | `TIME` with `extended_types = TRUE` | `time64[us]` |
#' | `DATETIME` and `TIMESTAMP` with `extended_types = TRUE` | `timestamp[us, UTC]` |
#' | `NULL` only, no declared type | `null` |
#'
#' SQLite integers are 64-bit, so integer columns are always `int64`;
#' nanoarrow converts these to `double` by default,
#' use `bit64::integer64()` as the target type to keep the full range.
#' Dates, times and timestamps are parsed like the data frame path does it
#' when `extended_types = TRUE`, see [SQLite()].
#' Times and timestamps are 64-bit counts of microseconds:
#' a number of seconds beyond about 9.2e12 either way, or an infinity, becomes `NULL` with a warning.
#' A time is a time of day, at least 0 and less than 24 hours:
#' other values, which the data frame path keeps as `hms` durations, become `NULL` with a warning.
#'
#' @section Parameters:
#' The columns of the parameter stream are bound like this:
#'
#' | *Arrow type* | *Bound as* |
#' | ------------ | ---------- |
#' | `null` | `NULL` |
#' | `bool`, `int8` to `int64`, `uint8` to `uint64` | integer |
#' | `float`, `double`, `decimal` | real |
#' | `utf8`, `large_utf8`, `utf8_view`, dictionaries of these | text |
#' | `binary`, `large_binary`, `fixed_size_binary`, `binary_view` | blob |
#' | `date32`, `date64` | real: days since 1970-01-01 |
#' | `time32`, `time64`, `duration` | real: seconds |
#' | `timestamp` | real: seconds since 1970-01-01 UTC |
#'
#' Nested types raise an error.
#' Named placeholders are matched to the names of the columns, like [DBI::dbBind()] does it.
#'
#' @section Data frames:
#' With `dbConnect(arrow = TRUE)`, data frames travel through this interface:
#' [DBI::dbFetch()] converts Arrow arrays filled straight from the SQLite statement,
#' and [DBI::dbAppendTable()] writes the data frame as an Arrow stream through [DBI::dbAppendTableArrow()].
#' The conversion follows nanoarrow's rules, with these additions:
#' an `int64` column becomes an `integer` if all its values fit,
#' and follows the `bigint` argument of [DBI::dbConnect()] otherwise, also in the later fetches of the result;
#' a `null` column becomes a `logical`.
#' `date32` columns become `Date` and `binary` columns become [blob::blob] objects,
#' as on the default path.
#' Times and timestamps become `hms` and `POSIXct` in UTC,
#' and travel as doubles in seconds in both directions,
#' so they keep the default path's precision and range, where a stream has microseconds.
#' A text value ends at its first NUL character, as on the default path,
#' where a stream keeps all its bytes.
#'
#' Unlike a stream, each fetch decides the types of its columns, the way the default path does it:
#' the first value that is not `NULL` decides,
#' integers become doubles when a real number follows in the same fetch,
#' and a column without a value takes its declared type, or `logical` without one.
#' The next fetch starts from these types, also after [DBI::dbBind()],
#' except that it decides a `logical` column again.
#' Two differences remain.
#' The default path truncates a real number that follows an integer too large for an `integer`,
#' here the column becomes a `double`,
#' which keeps the real number but rounds the integers beyond `2^53`.
#' The default path reads `-2147483648` as a 32-bit integer, which is `NA` in R,
#' here it is a value that needs 64 bits.
#' Once [DBI::dbFetchArrow()] or [DBI::dbFetchArrowChunk()] has fixed the types of a result,
#' later fetches keep them, with times and timestamps in microseconds,
#' and they hand out the rows kept for a schema and a row held back by the byte limits,
#' where the default path fails.
#' Before writing, factors become strings, lists of raw vectors become blobs,
#' and `difftime`, `POSIXct` and `Date` columns become their numbers in their own units,
#' as on the default path.
#'
#' Each fetch reads its rows into Arrow arrays first,
#' so that the data frame is allocated once with the row count known,
#' and releases each array as soon as it is converted:
#' at its peak, the memory holds the arrays and the part of the data frame filled so far.
#'
#' @section Chunking:
#' [DBI::dbFetchArrow()] returns a nanoarrow array stream that is read lazily:
#' each array holds at most `chunk_size` rows,
#' fetched from the result when the array is requested,
#' so the memory footprint is that of one chunk, not of the result set.
#' The stream holds on to the statement of the result:
#' it stays readable after [DBI::dbClearResult()], while other queries run on the same connection,
#' and even after [DBI::dbDisconnect()],
#' when an error of the statement can only report SQLite's generic message for its result code.
#' Until it has been read to the end or released, with `stream$release()` or by the garbage collector,
#' it keeps the statement open, and with it a read transaction and the database file.
#' It reads the rows of the parameters bound when it was created:
#' once [DBI::dbBind()] or [DBI::dbBindArrow()] binds new parameters, reading it fails,
#' and [DBI::dbFetchArrow()] returns a stream for the new rows.
#' [DBI::dbFetchArrowChunk()] returns one such array per call,
#' and an empty array once all rows are fetched.
#' When the schema of a stream is requested before its first array,
#' the first chunk is fetched to decide the types and kept for the next fetch:
#' [DBI::dbGetRowCount()] and [DBI::dbHasCompleted()] count its rows once they have been handed out,
#' and [DBI::dbFetch()] fails while they wait.
#' A chunk also ends after the row at which a string or binary column reaches 1 GiB,
#' and before a row that would take such a column past the `2^31 - 1` bytes
#' that the 32-bit offsets of the `utf8` and `binary` types can address.
#' Such a row waits for the next Arrow fetch, and [DBI::dbFetch()] fails until then.
#'
#' An array returned by [DBI::dbFetchArrowChunk()] is freed
#' when the garbage collector finds it unreachable,
#' and the collector does not see the memory that nanoarrow allocated for it.
#' After every 64 MB of arrays, RSQLite triggers a collection of the young generation,
#' so that a loop that discards its chunks holds at most that much garbage.
#' A loop that needs to be tighter releases each array
#' with `nanoarrow::nanoarrow_pointer_release()` once done with it.
#'
#' @name sqlite-arrow
#' @aliases arrow
NULL

# An array that dbFetchArrowChunk() handed out is freed when the garbage
# collector finds it unreachable, and the collector does not see the memory
# that nanoarrow allocated for it: a loop that discards its chunks could pile
# up the whole result as garbage before a collection happens on its own.
# A collection of the young generation every ARROW_GC_BYTES of arrays bounds that.
ARROW_GC_BYTES <- 64 * 1024^2

arrow_gc_state <- new.env(parent = emptyenv())
arrow_gc_state$bytes <- 0

arrow_chunk_handed_out <- function(bytes) {
  arrow_gc_state$bytes <- arrow_gc_state$bytes + bytes
  if (arrow_gc_state$bytes >= ARROW_GC_BYTES) {
    arrow_gc_state$bytes <- 0
    arrow_gc()
  }
  invisible()
}

# R < 3.5.0 has no partial collection
arrow_gc <- if ("full" %in% names(formals(gc))) {
  function() gc(full = FALSE)
} else {
  function() gc()
}

check_chunk_size <- function(chunk_size) {
  if (!is.numeric(chunk_size) || length(chunk_size) != 1L || !is.finite(chunk_size) ||
    chunk_size < 1 || trunc(chunk_size) != chunk_size) {
    stopc("`chunk_size` must be a positive whole number")
  }
  # The C++ code takes a 64-bit integer, doubles are whole numbers up to 2^53
  min(as.numeric(chunk_size), 2^53)
}

# The names of the columns of a struct schema, "" for unnamed columns
arrow_schema_names <- function(schema) {
  vapply(
    schema$children,
    function(child) if (is.null(child$name)) "" else child$name,
    character(1),
    USE.NAMES = FALSE
  )
}

# A zero-row data frame with the R types that correspond to an Arrow schema,
# from which dbDataType() derives the column types of a new table:
# nanoarrow maps 64-bit integers to double, integer64 keeps their range.
arrow_ptype <- function(schema) {
  ptype <- nanoarrow::infer_nanoarrow_ptype(schema)
  formats <- vapply(schema$children, function(child) child$format, character(1))
  for (i in which(formats %in% c("l", "L"))) {
    ptype[[i]] <- bit64::integer64()
  }
  ptype
}
