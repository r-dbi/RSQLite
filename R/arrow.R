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
#' [DBI::dbFetch()] converts the arrays filled by [DBI::dbFetchArrowChunk()],
#' and [DBI::dbAppendTable()] writes the data frame as an Arrow stream through [DBI::dbAppendTableArrow()].
#' The conversion follows nanoarrow's rules, with these additions:
#' an `int64` column becomes an `integer` if all its values fit,
#' and follows the `bigint` argument of [DBI::dbConnect()] otherwise;
#' a `null` column becomes a `logical`.
#' `date32`, `time64` and `timestamp` columns become `Date`, `hms` and `POSIXct` in UTC,
#' and `binary` columns become [blob::blob] objects,
#' as on the default path.
#' The first chunk of a result decides the types of all its chunks.
#' Before writing, factors become strings and lists of raw vectors become blobs.
#'
#' @section Chunking:
#' [DBI::dbFetchArrow()] returns a nanoarrow array stream that is read lazily:
#' each array holds at most `chunk_size` rows,
#' fetched from the result when the array is requested,
#' so the memory footprint is that of one chunk, not of the result set.
#' The stream stays readable after the result has been cleared with [DBI::dbClearResult()],
#' it is invalidated when another query is sent on the same connection.
#' [DBI::dbFetchArrowChunk()] returns one such array per call,
#' and an empty array once all rows are fetched.
#' A chunk is also cut once a string or binary column holds one gigabyte.
#'
#' @name sqlite-arrow
#' @aliases arrow
NULL

check_chunk_size <- function(chunk_size) {
  if (!is.numeric(chunk_size) || length(chunk_size) != 1L || is.na(chunk_size) ||
    chunk_size < 1 || trunc(chunk_size) != chunk_size) {
    stopc("`chunk_size` must be a positive whole number")
  }
  as.numeric(chunk_size)
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
