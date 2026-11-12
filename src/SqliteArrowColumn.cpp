#include "pch.h"
#include "SqliteArrowColumn.h"
#include "SqliteColumnDataSource.h"
#include "affinity.h"
#include "utf8.h"
#include <cmath>
#include <cstdint>
#include <stdexcept>

SqliteArrowColumn::SqliteArrowColumn(
  sqlite3_stmt* stmt_,
  const int j_,
  const std::string& name_,
  bool with_alt_types
)
    : stmt(stmt_),
      j(j_),
      name(name_),
      kind(AK_UNDECIDED),
      frozen(false),
      pending_nulls(0),
      row(0) {
  if (!with_alt_types) {
    return;
  }
  // The declared types that the data frame path reads as dates and times
  switch (SqliteColumnDataSource::datatype_from_decltype(
    sqlite3_column_decltype(stmt, j),
    true
  )) {
  case DT_DATE:
    kind = AK_DATE32;
    break;
  case DT_TIME:
    kind = AK_TIME64;
    break;
  case DT_DATETIME:
    kind = AK_TIMESTAMP;
    break;
  default:
    break;
  }
}

bool SqliteArrowColumn::decided() const {
  return kind != AK_UNDECIDED;
}

void SqliteArrowColumn::decide_from_decltype() {
  if (decided()) {
    return;
  }
  kind = kind_from_decltype();
}

void SqliteArrowColumn::freeze() {
  frozen = true;
}

void SqliteArrowColumn::set_schema(struct ArrowSchema* schema) const {
  enum ArrowType type;
  switch (kind) {
  case AK_NA:
    type = NANOARROW_TYPE_NA;
    break;
  case AK_INT64:
    type = NANOARROW_TYPE_INT64;
    break;
  case AK_DOUBLE:
    type = NANOARROW_TYPE_DOUBLE;
    break;
  case AK_STRING:
    type = NANOARROW_TYPE_STRING;
    break;
  case AK_BINARY:
    type = NANOARROW_TYPE_BINARY;
    break;
  case AK_DATE32:
    type = NANOARROW_TYPE_DATE32;
    break;
  case AK_TIME64:
    type = NANOARROW_TYPE_TIME64;
    break;
  case AK_TIMESTAMP:
    type = NANOARROW_TYPE_TIMESTAMP;
    break;
  case AK_UNDECIDED:
  default:
    throw std::runtime_error("Internal error: Arrow type not decided");
  }

  if (kind == AK_TIME64 || kind == AK_TIMESTAMP) {
    check_arrow(
      ArrowSchemaSetTypeDateTime(
        schema,
        type,
        NANOARROW_TIME_UNIT_MICRO,
        (kind == AK_TIMESTAMP) ? "UTC" : NULL
      ),
      "Can't set Arrow type"
    );
  } else {
    check_arrow(ArrowSchemaSetType(schema, type), "Can't set Arrow type");
  }
  check_arrow(ArrowSchemaSetName(schema, name.c_str()), "Can't set Arrow name");
}

// Chunk building //////////////////////////////////////////////////////////////

void SqliteArrowColumn::start_chunk() {
  array.reset();
  pending_nulls = 0;
  text_reals.clear();
  // Also the values of a chunk that failed
  coercions.clear();
  if (decided()) {
    init_array();
  }
}

void SqliteArrowColumn::append_row(int64_t row_) {
  const int column_type = sqlite3_column_type(stmt, j);
  row = row_;

  if (!decided()) {
    if (column_type == SQLITE_NULL) {
      ++pending_nulls;
      return;
    }
    kind = kind_from_column_type(column_type);
    init_array();
    check_arrow(
      ArrowArrayAppendNull(array.get(), pending_nulls),
      "Can't append to Arrow array"
    );
    pending_nulls = 0;
  }

  if (column_type == SQLITE_NULL) {
    append_null();
    return;
  }

  append_value(column_type);
}

void SqliteArrowColumn::finish_chunk(int64_t n) {
  if (decided()) {
    return;
  }
  // Every value of this chunk was NULL, this is the last chance to decide
  decide_from_decltype();
  init_array();
  check_arrow(
    ArrowArrayAppendNull(array.get(), n),
    "Can't append to Arrow array"
  );
  pending_nulls = 0;
}

void SqliteArrowColumn::move_chunk_to(struct ArrowArray* out) {
  ArrowArrayMove(array.get(), out);
}

cpp11::sexp SqliteArrowColumn::take_coercions() {
  using namespace cpp11::literals;
  if (coercions.empty()) {
    return R_NilValue;
  }
  cpp11::writable::list out(
    { "column"_nm = name,
      "type"_nm = type_name(),
      "values"_nm = coercions.as_list() }
  );
  coercions.clear();
  return out;
}

// Privates ////////////////////////////////////////////////////////////////////

ARROW_KIND SqliteArrowColumn::kind_from_column_type(int column_type) {
  switch (column_type) {
  case SQLITE_INTEGER:
    return AK_INT64;
  case SQLITE_FLOAT:
    return AK_DOUBLE;
  case SQLITE_TEXT:
    return AK_STRING;
  case SQLITE_BLOB:
    return AK_BINARY;
  default:
    return AK_UNDECIDED;
  }
}

ARROW_KIND SqliteArrowColumn::kind_from_decltype() const {
  const char* decl_type = sqlite3_column_decltype(stmt, j);
  if (decl_type == NULL) {
    return AK_NA;
  }

  switch (sqlite3AffinityType(decl_type)) {
  case SQLITE_AFF_INTEGER:
    return AK_INT64;
  case SQLITE_AFF_NUMERIC:
  case SQLITE_AFF_REAL:
    return AK_DOUBLE;
  case SQLITE_AFF_TEXT:
    return AK_STRING;
  case SQLITE_AFF_BLOB:
    return AK_BINARY;
  default:
    // Doesn't occur
    return AK_NA;
  }
}

void SqliteArrowColumn::init_array() {
  nanoarrow::UniqueSchema schema;
  ArrowSchemaInit(schema.get());
  set_schema(schema.get());

  struct ArrowError error;
  ArrowErrorInit(&error);
  array.reset();
  check_arrow(
    ArrowArrayInitFromSchema(array.get(), schema.get(), &error),
    "Can't allocate Arrow array",
    &error
  );
  check_arrow(
    ArrowArrayStartAppending(array.get()),
    "Can't allocate Arrow array"
  );
}

// Values of another storage class than the type of their column
// are read as SQLite converts them:
// text and blobs in an int64 or double column, integers in a double column,
// numbers in a utf8 or binary column as the text SQLite renders,
// and text in a binary column as its UTF-8 bytes.
// A blob in a utf8 column keeps its bytes, which must be valid UTF-8.
// Text and blobs in an int64 column that a real widens later in the same chunk
// take the readings as reals that they would have in a double column.
// Once the type is fixed, a real in an int64 column is truncated toward zero.
// Dates, times and timestamps are read as append_date() and append_time() say.
// NULL takes the place of
// text or a blob in a utf8 column that isn't valid UTF-8 or holds a NUL byte,
// an integer that SQLite would saturate in an int64 column,
// a date or time that can't be parsed or is beyond the range of its type,
// and any value in a column of the null type.
// Each value that these rules convert or make NULL is logged with note(),
// except an integer in a double column and a number within the range
// of a date or time column, which dbFetch() reads the same way without warning.
void SqliteArrowColumn::append_value(int column_type) {
  switch (kind) {
  case AK_INT64:
    if (column_type == SQLITE_FLOAT && !frozen) {
      // The type is still open: a real value widens the column
      promote_to_double();
      append_value(column_type);
      return;
    }
    if ((column_type == SQLITE_TEXT || column_type == SQLITE_BLOB) && !frozen) {
      // For a real that may widen the column later in this chunk
      text_reals.push_back(std::make_pair(array->length, text_real()));
    }
    append_int64(column_type);
    break;

  case AK_DOUBLE:
    if (column_type == SQLITE_TEXT || column_type == SQLITE_BLOB) {
      const double real = text_real();
      note(column_type, CR_CONVERTED);
      check_arrow(
        ArrowArrayAppendDouble(array.get(), real),
        "Can't append to Arrow array"
      );
      break;
    }
    check_arrow(
      ArrowArrayAppendDouble(array.get(), sqlite3_column_double(stmt, j)),
      "Can't append to Arrow array"
    );
    break;

  case AK_STRING:
    append_string(column_type);
    break;

  case AK_BINARY:
    if (column_type != SQLITE_BLOB) {
      note(column_type, CR_CONVERTED);
    }
    check_arrow(
      ArrowArrayAppendBytes(array.get(), value_bytes(column_type)),
      "Can't append to Arrow array"
    );
    break;

  case AK_DATE32:
    append_date(column_type);
    break;

  case AK_TIME64:
  case AK_TIMESTAMP:
    append_time(column_type);
    break;

  case AK_NA:
    note(column_type, CR_NULL_TYPE);
    append_null();
    break;

  case AK_UNDECIDED:
    throw std::runtime_error("Internal error: Arrow type not decided");
  }
}

void SqliteArrowColumn::append_int64(int column_type) {
  int64_t value;
  if (!integer_value(column_type, value)) {
    note(column_type, CR_OUT_OF_RANGE);
    append_null();
    return;
  }
  if (column_type != SQLITE_INTEGER) {
    note(column_type, CR_CONVERTED);
  }
  check_arrow(
    ArrowArrayAppendInt(array.get(), value),
    "Can't append to Arrow array"
  );
}

// Whether the magnitude of the integer at the start of `text` fits int64,
// read as SQLite reads text into an integer: after spaces and a sign,
// the digits up to the first other character
static bool leading_integer_fits(const char* text, int size) {
  const char* end = text + size;
  while (text < end && (*text == ' ' || (*text >= '\t' && *text <= '\r'))) {
    ++text;
  }
  bool negative = false;
  if (text < end && (*text == '-' || *text == '+')) {
    negative = (*text == '-');
    ++text;
  }
  // A negative integer reaches the magnitude of INT64_MIN
  const uint64_t limit = negative ? UINT64_C(9223372036854775808) : INT64_MAX;
  uint64_t magnitude = 0;
  for (; text < end && *text >= '0' && *text <= '9'; ++text) {
    const unsigned digit = static_cast<unsigned>(*text - '0');
    if (magnitude > (limit - digit) / 10) {
      return false;
    }
    magnitude = magnitude * 10 + digit;
  }
  return true;
}

// The integer of the current value, as SQLite reads it, into `value`.
// False where SQLite would saturate it: a real beyond the range of int64,
// or text and blobs whose leading integer is.
bool SqliteArrowColumn::integer_value(int column_type, int64_t& value) const {
  if (column_type == SQLITE_FLOAT) {
    // Truncated toward zero as SQLite does it.
    // Both bounds are exact as doubles, and casting a value outside,
    // an infinity included, would be undefined.
    double real = std::trunc(sqlite3_column_double(stmt, j));
    if (!(real >= -9223372036854775808.0 && real < 9223372036854775808.0)) {
      return false;
    }
    value = static_cast<int64_t>(real);
    return true;
  }

  value = sqlite3_column_int64(stmt, j);
  if (column_type == SQLITE_INTEGER ||
      (value != INT64_MAX && value != INT64_MIN)) {
    return true;
  }
  // SQLite saturates the leading integer of text and blobs,
  // which it reads as text in the encoding of the database
  const char* text = value_text();
  return leading_integer_fits(text, sqlite3_column_bytes(stmt, j));
}

void SqliteArrowColumn::append_string(int column_type) {
  const struct ArrowBufferView bytes = value_bytes(column_type);
  // SQLite doesn't enforce UTF-8 for text, and a blob keeps all its bytes:
  // only well-formed UTF-8 without NUL bytes is text, as R strings need it.
  // Numbers render as ASCII.
  if ((column_type == SQLITE_TEXT || column_type == SQLITE_BLOB) &&
      !rsqlite_is_utf8_string(
        bytes.data.as_char,
        static_cast<size_t>(bytes.size_bytes)
      )) {
    note(column_type, CR_INVALID_UTF8);
    append_null();
    return;
  }
  if (column_type != SQLITE_TEXT) {
    note(column_type, CR_CONVERTED);
  }
  struct ArrowStringView view;
  view.data = bytes.data.as_char;
  view.size_bytes = bytes.size_bytes;
  check_arrow(
    ArrowArrayAppendString(array.get(), view),
    "Can't append to Arrow array"
  );
}

// The bytes of the current value for a utf8 or binary column.
// A blob keeps its bytes, also in a utf8 column: sqlite3_column_text()
// would take them for text in the encoding of the database,
// and transcode them in a UTF-16 one.
// Text and numbers are read as UTF-8 text, also in a binary column,
// as the data frame path reads them.
struct ArrowBufferView SqliteArrowColumn::value_bytes(int column_type) const {
  struct ArrowBufferView out;
  if (column_type != SQLITE_BLOB) {
    // sqlite3_column_text() converts the value,
    // and must come before sqlite3_column_bytes()
    out.data.data = value_text();
    out.size_bytes = sqlite3_column_bytes(stmt, j);
    return out;
  }

  // The size of a blob needs no conversion, and comes first:
  // sqlite3_column_blob() gives NULL for a blob of no bytes,
  // and also if it runs out of memory while expanding a zeroblob()
  out.size_bytes = sqlite3_column_bytes(stmt, j);
  out.data.data = sqlite3_column_blob(stmt, j);
  if (out.data.data == NULL) {
    if (out.size_bytes > 0) {
      stop_out_of_memory();
    }
    out.data.data = "";
  }
  return out;
}

// The current value as UTF-8 text, as SQLite converts it.
// For a value that isn't NULL, sqlite3_column_text() gives NULL
// only if the conversion runs out of memory.
// SQLite fails the next step then,
// but after a full chunk that step only reads ahead,
// and keeps its error for the next fetch:
// the chunk would come back with a wrong value.
const char* SqliteArrowColumn::value_text() const {
  const unsigned char* text = sqlite3_column_text(stmt, j);
  if (text == NULL) {
    stop_out_of_memory();
  }
  return reinterpret_cast<const char*>(text);
}

// Text or a blob as SQLite reads it into a real.
// Reading it as UTF-8 text first tells a failed conversion from a zero,
// and leaves sqlite3_column_double() nothing to allocate.
double SqliteArrowColumn::text_real() const {
  value_text();
  return sqlite3_column_double(stmt, j);
}

// The days since 1970-01-01, as the data frame path reads a date:
// text as SqliteColumnDataSource::parse_date() parses it,
// and a number as a count of days, truncated toward zero.
// The data frame path reads that count in 32 bits, which wraps beyond them,
// so here it is read in full and NULL beyond the range of date32.
// A blob is NULL, as the data frame path doesn't convert it.
void SqliteArrowColumn::append_date(int column_type) {
  int64_t days = 0;
  bool ok = false;
  if (column_type == SQLITE_INTEGER) {
    days = sqlite3_column_int64(stmt, j);
    ok = days >= INT32_MIN && days <= INT32_MAX;
  } else if (column_type == SQLITE_FLOAT) {
    const double real = std::trunc(sqlite3_column_double(stmt, j));
    // False for an infinity
    ok = real >= INT32_MIN && real <= INT32_MAX;
    if (ok) {
      days = static_cast<int64_t>(real);
    }
  } else if (column_type == SQLITE_TEXT) {
    // The years 1400 to 9999, well within date32
    ok = SqliteColumnDataSource::parse_date(value_text(), days);
  }

  if (!ok) {
    // Numbers fail by their range, text and blobs by their parsing
    note(
      column_type,
      (column_type == SQLITE_INTEGER || column_type == SQLITE_FLOAT)
        ? CR_OUT_OF_RANGE
        : CR_UNPARSABLE
    );
    append_null();
    return;
  }
  check_arrow(
    ArrowArrayAppendInt(array.get(), days),
    "Can't append to Arrow array"
  );
}

// The microseconds of a time since midnight, or of a timestamp since
// 1970-01-01 00:00:00 UTC, as the data frame path reads their seconds:
// text as SqliteColumnDataSource::parse_time() or parse_datetime_local()
// parses it, and a number as seconds, rounded to the nearest microsecond.
// A blob is NULL, as the data frame path doesn't convert it,
// and so is a number beyond the range of int64 microseconds,
// and a time outside the day that time64 holds,
// which the data frame path keeps as a duration.
void SqliteArrowColumn::append_time(int column_type) {
  static const int64_t day = INT64_C(86400000000);

  int64_t micros = 0;
  bool ok = false;
  // False for text that can't be parsed and for a blob
  bool parsed = true;
  if (column_type == SQLITE_INTEGER) {
    const int64_t seconds = sqlite3_column_int64(stmt, j);
    ok = seconds >= -INT64_MAX / 1000000 && seconds <= INT64_MAX / 1000000;
    if (ok) {
      micros = seconds * 1000000;
    }
  } else if (column_type == SQLITE_FLOAT) {
    const double seconds = sqlite3_column_double(stmt, j);
    // To the nearest microsecond, halves to even in the default rounding mode.
    // Adding 0.5 and rounding down would round an odd count between 2^52 and
    // 2^53 one up: the count is exact there, and adding 0.5 makes a tie.
    // Both bounds are exact as doubles, and casting a value outside,
    // an infinity included, would be undefined.
    const double rounded = std::nearbyint(seconds * 1e6);
    ok = rounded >= -9223372036854775808.0 && rounded < 9223372036854775808.0;
    if (ok) {
      micros = static_cast<int64_t>(rounded);
    }
    // Rounding a time before midnight stops at the last microsecond of the day
    if (kind == AK_TIME64 && micros == day && seconds < 86400) {
      micros = day - 1;
    }
  } else if (column_type == SQLITE_TEXT) {
    const char* text = value_text();
    ok = (kind == AK_TIMESTAMP)
           ? SqliteColumnDataSource::parse_datetime_local(text, micros)
           : SqliteColumnDataSource::parse_time(text, micros);
    parsed = ok;
  } else {
    parsed = false;
  }

  if (kind == AK_TIME64) {
    ok = ok && micros >= 0 && micros < day;
  }
  if (!ok) {
    note(column_type, parsed ? CR_OUT_OF_RANGE : CR_UNPARSABLE);
    append_null();
    return;
  }
  check_arrow(
    ArrowArrayAppendInt(array.get(), micros),
    "Can't append to Arrow array"
  );
}

void SqliteArrowColumn::append_null() {
  check_arrow(
    ArrowArrayAppendNull(array.get(), 1),
    "Can't append to Arrow array"
  );
}

// Rebuilds the int64 array collected so far as a double array
void SqliteArrowColumn::promote_to_double() {
  nanoarrow::UniqueArray ints;
  ArrowArrayMove(array.get(), ints.get());
  int64_t n = ints->length;
  const int64_t* values =
    reinterpret_cast<const int64_t*>(ArrowArrayBuffer(ints.get(), 1)->data);
  const struct ArrowBitmap* validity = ArrowArrayValidityBitmap(ints.get());
  bool has_nulls = validity->buffer.size_bytes > 0;

  kind = AK_DOUBLE;
  init_array();

  // Text and blobs take their reading as reals, in the order of their rows
  std::vector<std::pair<int64_t, double> >::const_iterator text =
    text_reals.begin();
  for (int64_t i = 0; i < n; ++i) {
    double value = static_cast<double>(values[i]);
    if (text != text_reals.end() && text->first == i) {
      value = (text++)->second;
    } else if (has_nulls && !ArrowBitGet(validity->buffer.data, i)) {
      append_null();
      continue;
    }
    check_arrow(
      ArrowArrayAppendDouble(array.get(), value),
      "Can't append to Arrow array"
    );
  }
  text_reals.clear();
  // Text and blobs that saturated as integers are reals now
  coercions.merge(SQLITE_TEXT, CR_OUT_OF_RANGE, CR_CONVERTED);
  coercions.merge(SQLITE_BLOB, CR_OUT_OF_RANGE, CR_CONVERTED);
}

void SqliteArrowColumn::stop_out_of_memory() const {
  throw std::runtime_error(
    "Column `" + name + "`: out of memory while reading a value."
  );
}

void SqliteArrowColumn::note(int column_type, COERCION_REASON reason) {
  coercions.record(column_type, reason, row);
}

// The type as the warning about the values of a chunk names it
const char* SqliteArrowColumn::type_name() const {
  switch (kind) {
  case AK_NA:
    return "null";
  case AK_INT64:
    return "int64";
  case AK_DOUBLE:
    return "double";
  case AK_STRING:
    return "utf8";
  case AK_BINARY:
    return "binary";
  case AK_DATE32:
    return "date32";
  case AK_TIME64:
    return "time64[us]";
  case AK_TIMESTAMP:
    return "timestamp[us, UTC]";
  case AK_UNDECIDED:
  default:
    // Doesn't occur: a chunk decides the type of every column
    return "undecided";
  }
}
