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
#' Once the first chunk has been fetched the types are fixed,
#' and a value of another storage class is converted by SQLite's own rules.
#' The types can therefore depend on `chunk_size`:
#' a real number in a later chunk is truncated to fit an `int64` column decided from integers,
#' and a column whose first chunk holds only `NULL` keeps its declared type,
#' or the null type without a declaration, for the whole result.
#' The default chunk size makes this rare, a small `chunk_size` makes it likely,
#' and a `schema` fixes the types up front, see the section on requesting types.
#' A value in a column of the null type becomes `NULL`.
#' Text and blobs in a `utf8` column are kept only if they are valid UTF-8 without NUL bytes,
#' which SQLite does not enforce,
#' and a date, time or timestamp that cannot be parsed is dropped;
#' both become `NULL`.
#' Text in a `binary` column is its UTF-8 bytes, also in a UTF-16 database, as on the data frame path.
#' Converted and dropped values are reported with one warning per chunk, of class `RSQLite_warning_coercion`,
#' that lists the affected columns with their types and the 1-based row numbers in the result.
#' It is raised when the chunk is fetched from the result:
#' for a lazy stream when the array is requested,
#' and for the first chunk when the schema is requested before it
#' and a column has no requested type, see the sections on chunking and on requesting types.
#' The warning carries the details in its `coercions` field.
#' A handler of the warning runs while the result is still busy with the chunk:
#' it gets an error if it fetches from, binds, inspects or clears that result.
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
#' a number of seconds beyond about 9.2e12 either way, or an infinity, becomes `NULL`.
#' A time is a time of day, at least 0 and less than 24 hours:
#' other values, which the data frame path keeps as `hms` durations, become `NULL`.
#' Both are reported as out of range in the warning about the chunk.
#'
#' @section Requesting types:
#' The `schema` argument of [DBI::dbSendQueryArrow()], [DBI::dbGetQueryArrow()]
#' and [DBI::dbReadTableArrow()] fixes the Arrow types of some or all result columns
#' before the first row is read:
#' a struct `nanoarrow_schema`, an arrow `Schema`,
#' or a named list of column types such as
#' `list(id = nanoarrow::na_int32(), when = nanoarrow::na_timestamp("ms", "UTC"))`.
#' The entries are matched to the result columns by name, exactly.
#' A name that is not in the result, a name the result carries twice,
#' and an unnamed entry are errors.
#' The names and types are checked once the query has been sent,
#' so a statement with side effects, such as `INSERT ... RETURNING`, has run when they fail.
#' A column with a requested type is typed without looking at its values,
#' with no widening and no dependence on `chunk_size`,
#' and its declared type and `extended_types` play no part;
#' the other columns are typed as described above.
#' The requested types are kept when the query is executed again with [DBI::dbBind()],
#' and by the data frame fetches of a connection with `arrow = TRUE`, see the section on data frames,
#' where nanoarrow converts them to R types.
#' There they take precedence over the types that a fetch carries over from an earlier execution,
#' and a requested time or timestamp has the requested unit and time zone,
#' where a decided one travels as seconds.
#'
#' The types that can be requested are
#' `null`, `bool`, `int8` to `int64`, `uint8` to `uint64`, `float`, `double`,
#' `utf8` and `large_utf8`, `binary` and `large_binary`, `date32` and `date64`,
#' `time32` and `time64` in any unit, and `timestamp` in any unit and time zone.
#' Dates, times and timestamps are parsed from their text form like `extended_types = TRUE` does it,
#' a timestamp is read as UTC and only labelled with the requested time zone.
#' A number is a count of days for a date, truncated, and of seconds for a time or timestamp.
#' Times and timestamps are rounded to the nearest tick of their unit,
#' a time to the last tick of the day at most:
#' exactly for an integer and for text, which is read to the microsecond,
#' and in double precision for a real.
#' Dictionary, decimal, nested and extension types are an error.
#'
#' Values of another storage class than the column's type follow these rules,
#' whether the type was requested or decided from the values:
#'
#' * silently: integers into a floating point type,
#'   integers and reals into a text type, where SQLite renders them,
#'   and text into a binary type, as its bytes;
#' * converted by SQLite, with the warning described above:
#'   text and blobs into a numeric type,
#'   and reals into an integer type, truncated, or into `bool`, true unless zero;
#' * `NULL`, with the warning: a blob into a text type unless it is valid UTF-8 without NUL bytes,
#'   like text itself, see above,
#'   a number outside the range of an integer type,
#'   including a real or the integer at the start of a text beyond 64 bits, which SQLite would saturate,
#'   a finite number beyond the range of `float`,
#'   a date outside the range of its type, such as a number of days beyond `2^31 - 1` for `date32`,
#'   a time outside a day, from 0 up to 24 hours excluded,
#'   a timestamp outside the range of its unit, such as nanoseconds after 2262,
#'   a date or time that cannot be parsed,
#'   and any value into the null type.
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
#' a requested `uint64` column does the same,
#' but becomes a `double` once a value is beyond `2^63 - 1`, which `integer64` cannot hold,
#' also in the later fetches until the query is bound again,
#' where nanoarrow would wrap such a value to a negative `integer64` and the stream holds it exactly;
#' a `null` column becomes a `logical`.
#' `date32` columns become `Date` and `binary` columns become [blob::blob] objects,
#' as on the default path.
#' Times and timestamps become `hms` and `POSIXct` in UTC,
#' and travel as doubles in seconds in both directions unless their type was requested,
#' so they keep the default path's precision and range, times outside a day included,
#' where a stream has microseconds and only times of day.
#' Text ends at its first NUL character and is not checked for UTF-8, as on the default path,
#' where a stream makes text `NULL` unless it is valid UTF-8 without NUL bytes.
#' A blob in a text column is text only if it is valid UTF-8 without NUL bytes, as in a stream,
#' and `NA` otherwise, reported in the warning of the fetch,
#' where the default path ends it at its first NUL byte and does not check it.
#'
#' Unlike a stream, each fetch decides the types of its columns without a requested type,
#' the way the default path does it:
#' the first value that is not `NULL` decides,
#' integers become doubles when a real number follows in the same fetch,
#' and a column without a value takes its declared type, or `logical` without one.
#' The next fetch starts from these types, also after [DBI::dbBind()],
#' except that it decides a `logical` column again.
#' [DBI::dbColumnInfo()] names the types that a fetch of no rows returns,
#' and decides them for the next fetch like on the default path,
#' without converting the values of the next row.
#' Four differences remain.
#' The default path truncates a real number that follows an integer too large for an `integer`,
#' with a warning, here the column becomes a `double`,
#' which keeps the real number but rounds the integers beyond `2^53`.
#' It also truncates a string or blob converted to an integer too large for an `integer`,
#' here the column follows `bigint` from then on, as for such an integer.
#' The default path reads `-2147483648` as a 32-bit integer, which is `NA` in R,
#' here it is a value that needs 64 bits.
#' With `extended_types = TRUE`, the default path reads a number in a `DATE` column as days in 32 bits
#' and wraps a larger one into another date without a warning,
#' here such a number is `NA` and reported as out of range;
#' numbers in `TIME` and `TIMESTAMP` columns are seconds on both paths.
#' Once [DBI::dbFetchArrow()] or [DBI::dbFetchArrowChunk()] has fixed the types of a result,
#' later fetches keep them and the rules of a stream,
#' with times and timestamps in microseconds, and text checked like a blob,
#' and they hand out the rows kept for a schema and a row held back by the byte limits,
#' where the default path fails.
#' Values that are not of their column's type are converted or dropped as in a stream,
#' and reported with one warning of class `RSQLite_warning_coercion` per [DBI::dbFetch()],
#' which names the Arrow types the columns have at the end of the fetch.
#' It is raised once the fetch has returned its rows,
#' so a handler of the warning can use the result,
#' where the default path warns while it fetches and a handler that uses the result raises an error.
#' The default path warns on the same fetches,
#' apart from the values converted silently, as listed in the section on requesting types,
#' and the numbers of days beyond 32 bits, which it wraps,
#' but once per column with values of another storage class,
#' and once per date, time or timestamp that cannot be parsed.
#' It also warns about the real numbers it truncates,
#' and in a fetch of no rows about the next row, from which it types the columns;
#' through Arrow, a fetch of no rows returns no value and never warns.
#' Before writing, factors become strings, lists of raw vectors become blobs,
#' `POSIXlt` columns, which the default path can't write, become `POSIXct`,
#' and `difftime`, `POSIXct` and `Date` columns become their numbers in their own units,
#' as on the default path.
#'
#' The `ptype` argument of [DBI::dbSendQuery()], [DBI::dbGetQuery()] and [DBI::dbReadTable()]
#' fixes the R types of some or all result columns before the first row is read:
#' a data frame, or a named list of vectors whose values are ignored, such as
#' `list(id = bit64::integer64(), when = as.POSIXct(character(), tz = "UTC"))`.
#' The columns are matched to the result by name, exactly, with the errors of `schema`,
#' and the two arguments can't be combined in [DBI::dbSendQueryArrow()] or [DBI::dbGetQueryArrow()].
#' A column of the prototype is requested from SQLite as the Arrow type that
#' `nanoarrow::infer_nanoarrow_schema()` gives for it, see the section on requesting types:
#' `integer` as `int32`, so that values outside its range become `NA` with a warning,
#' `bit64::integer64` as `int64`, `logical` as `bool`, `Date` as `date32`, and `blob` as `binary`.
#' `POSIXct`, `POSIXlt` and `hms` columns are requested as `timestamp[us]` and `time64[us]`,
#' but read like the times and timestamps decided from `extended_types`, whatever the declared type:
#' as doubles in seconds, with the default path's precision and range, times outside a day included,
#' until an Arrow stream fixes the types of the result, see above.
#' The timestamps are read as UTC, like on both paths,
#' and take the time zone of the prototype, the session's time zone for an empty one.
#' A factor is read as text and converted to its levels, where other values become `NA` as with [base::factor()],
#' or to the levels found in the values of each fetch if it has none.
#' A prototype that nanoarrow finds no type for, one of a type that cannot be requested, such as a `difftime`,
#' and one that nanoarrow cannot convert back to, such as an [AsIs][base::I] vector, are errors that name the column.
#' These columns keep their types in every fetch, whatever the values,
#' and come back exactly as described:
#' an `integer64` column stays one whatever the values and whatever `bigint` says.
#' The other columns are typed and converted as described above.
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
#' and a column has no requested type,
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

# Requests the Arrow types of `schema` for the columns of a result:
# a struct nanoarrow_schema, an arrow Schema, or a named list of column types;
# `arg` names the argument in error messages, and `seconds` marks the times and
# timestamps that data frame fetches store as doubles in seconds
arrow_set_schema <- function(res, schema, arg = "schema", seconds = NULL) {
  schema <- arrow_check_schema(schema)
  requested <- arrow_schema_names(schema)
  if (any(requested == "")) {
    stopc("All entries of `", arg, "` must be named")
  }
  if (anyDuplicated(requested)) {
    stopc(
      "Duplicate names in `", arg, "`: ",
      paste0("`", unique(requested[duplicated(requested)]), "`", collapse = ", ")
    )
  }

  columns <- result_column_names(res@ptr)
  positions <- match(requested, columns)
  if (anyNA(positions)) {
    stopc(
      "Columns of `", arg, "` not in the result: ",
      paste0("`", requested[is.na(positions)], "`", collapse = ", ")
    )
  }
  ambiguous <- requested[requested %in% columns[duplicated(columns)]]
  if (length(ambiguous) > 0) {
    stopc(
      "Columns of `", arg, "` that the result carries more than once: ",
      paste0("`", ambiguous, "`", collapse = ", ")
    )
  }

  if (is.null(seconds)) {
    seconds <- logical(length(requested))
  }
  result_set_arrow_schema(res@ptr, schema, positions - 1L, seconds)
  invisible(res)
}

arrow_check_schema <- function(schema) {
  if (is.data.frame(schema)) {
    stopc(
      "`schema` must describe Arrow types, ",
      "use `nanoarrow::infer_nanoarrow_schema()` for a data frame prototype"
    )
  }
  if (is.list(schema) && !inherits(schema, "nanoarrow_schema")) {
    if (length(schema) == 0 || is.null(names(schema)) || any(names(schema) == "")) {
      stopc("A list passed as `schema` must have named entries")
    }
    schema <- nanoarrow::na_struct(lapply(schema, nanoarrow::as_nanoarrow_schema))
  } else {
    schema <- nanoarrow::as_nanoarrow_schema(schema)
  }
  if (schema$format != "+s") {
    stopc("`schema` must be a struct schema, not ", schema$format)
  }
  schema
}

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
