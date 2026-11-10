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
#' Once the first chunk has been fetched the types are fixed.
#' A value of another storage class is converted by SQLite's own rules,
#' and becomes `NULL` in a column of the null type.
#' A blob in a text column is kept only if it is valid UTF-8 without NUL bytes,
#' and a date, time or timestamp that cannot be parsed is dropped;
#' both become `NULL`.
#' Such values are reported with one warning per chunk, of class `RSQLite_warning_coercion`,
#' that lists the affected columns with their types and the 1-based row numbers in the result.
#' It is raised when the chunk is fetched from the result:
#' for a lazy stream when the array is requested,
#' and for the first chunk when the schema is requested before it
#' and a column has no requested type, see the sections on chunking and on requesting types.
#' The warning carries the details in its `coercions` field.
#' The types can therefore depend on `chunk_size`:
#' a real number in a later chunk is truncated to fit an `int64` column decided from integers,
#' and a column whose first chunk holds only `NULL` keeps its declared type,
#' or the null type without a declaration, for the whole result.
#' The default chunk size makes this rare, a small `chunk_size` makes it likely,
#' and a `schema` fixes the types up front, see the section on requesting types.
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
#' A column with a requested type is typed without looking at its values,
#' with no widening and no dependence on `chunk_size`,
#' and its declared type and `extended_types` play no part;
#' the other columns are typed as described above.
#' The requested types are kept when the query is executed again with [DBI::dbBind()],
#' and by the data frame fetches of a connection with `arrow = TRUE`,
#' where nanoarrow converts them to R types.
#'
#' The types that can be requested are
#' `null`, `bool`, `int8` to `int64`, `uint8` to `uint64`, `float`, `double`,
#' `utf8` and `large_utf8`, `binary` and `large_binary`, `date32` and `date64`,
#' `time32` and `time64` in any unit, and `timestamp` in any unit and time zone.
#' Dates, times and timestamps are parsed from their text form like `extended_types = TRUE` does it,
#' a timestamp is read as UTC and only labelled with the requested time zone.
#' Dictionary, decimal, nested and extension types are an error.
#'
#' Values of another storage class than the column's type follow these rules,
#' whether the type was requested or decided from the values:
#'
#' * silently: integers into a floating point type,
#'   integers and reals into a text type, where SQLite renders them,
#'   and text into a binary type, as its bytes;
#' * converted by SQLite, with the warning described above:
#'   text and blobs into a numeric type, and reals into an integer type, truncated;
#' * `NULL`, with the warning: a blob into a text type unless it is valid UTF-8,
#'   a number outside the range of an integer type,
#'   a time or timestamp outside the range of its unit, such as a timestamp in nanoseconds after 2262,
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
#' a `null` column becomes a `logical`.
#' `date32`, `time64` and `timestamp` columns become `Date`, `hms` and `POSIXct` in UTC,
#' and `binary` columns become [blob::blob] objects,
#' as on the default path.
#'
#' Unlike a stream, each fetch decides the types of its columns without a requested type,
#' the way the default path does it:
#' the first value that is not `NULL` decides,
#' integers become doubles when a real number follows in the same fetch,
#' and a column without a value takes its declared type, or `logical` without one.
#' The next fetch starts from these types, except that it decides a `logical` column again.
#' The default path truncates a real number that follows an integer too large for an `integer`,
#' with a warning, here the column becomes a `double`.
#' Once [DBI::dbFetchArrow()] or [DBI::dbFetchArrowChunk()] has fixed the types of a result,
#' later fetches keep them,
#' and they hand out the rows kept for a schema, where the default path fails.
#' Values that are not of their column's type are converted or dropped as in a stream,
#' and reported with one warning of class `RSQLite_warning_coercion` per [DBI::dbFetch()],
#' which names the Arrow types the columns have at the end of the fetch.
#' The default path warns on the same fetches,
#' apart from the real numbers it truncates
#' and the values converted silently, as listed in the section on requesting types,
#' but once per column with values of another storage class,
#' and once per date, time or timestamp that cannot be parsed.
#' Before writing, factors become strings, lists of raw vectors become blobs,
#' and `difftime` columns become their numbers in their own units, as on the default path.
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
# a struct nanoarrow_schema, an arrow Schema, or a named list of column types
arrow_set_schema <- function(res, schema) {
  schema <- arrow_check_schema(schema)
  requested <- arrow_schema_names(schema)
  if (any(requested == "")) {
    stopc("All entries of `schema` must be named")
  }
  if (anyDuplicated(requested)) {
    stopc(
      "Duplicate names in `schema`: ",
      paste0("`", unique(requested[duplicated(requested)]), "`", collapse = ", ")
    )
  }

  columns <- result_column_names(res@ptr)
  positions <- match(requested, columns)
  if (anyNA(positions)) {
    stopc(
      "Columns of `schema` not in the result: ",
      paste0("`", requested[is.na(positions)], "`", collapse = ", ")
    )
  }
  ambiguous <- requested[requested %in% columns[duplicated(columns)]]
  if (length(ambiguous) > 0) {
    stopc(
      "Columns of `schema` that the result carries more than once: ",
      paste0("`", ambiguous, "`", collapse = ", ")
    )
  }

  result_set_arrow_schema(res@ptr, schema, positions - 1L)
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
