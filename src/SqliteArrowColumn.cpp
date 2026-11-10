#include "pch.h"
#include "SqliteArrowColumn.h"
#include "affinity.h"
#include "utf8.h"
#include <boost/algorithm/string/predicate.hpp>
#include <algorithm>
#include <climits>
#include <cmath>
#include <cstring>
#include <sstream>

// Whether `size` bytes of text are valid UTF-8 without NUL bytes.
// Most text is ASCII: eight bytes at a time, a word whose bytes are all in
// 1..127 needs no further check, the rest goes to rsqlite_is_utf8_string().
static bool is_utf8_text(const char* text, size_t size) {
  const uint64_t ones = UINT64_C(0x0101010101010101);
  const uint64_t highs = UINT64_C(0x8080808080808080);
  size_t i = 0;
  for (; i + 8 <= size; i += 8) {
    uint64_t word;
    memcpy(&word, text + i, 8);
    // A NUL byte borrows in `word - ones`, a byte above 127 has its high bit
    if (((word - ones) | word) & highs) {
      break;
    }
  }
  return rsqlite_is_utf8_string(text + i, size - i);
}

SqliteArrowColumn::SqliteArrowColumn(
  sqlite3_stmt* stmt_,
  const int j_,
  const std::string& name_,
  bool with_alt_types_
)
    : stmt(stmt_),
      j(j_),
      name(name_),
      with_alt_types(with_alt_types_),
      source(stmt_, j_, with_alt_types_),
      kind(AK_UNDECIDED),
      frozen(false),
      data_frame(false),
      array_kind(AK_UNDECIDED),
      pending_nulls(0),
      warned(false),
      warned_range(false),
      warned_utf8(false),
      wide_ints(false),
      value_type(SQLITE_NULL),
      value_data(NULL),
      value_size(0),
      value_fetched(false) {
  if (with_alt_types) {
    ARROW_KIND decl = kind_from_decltype();
    if (decl == AK_DATE || decl == AK_TIME || decl == AK_TIMESTAMP) {
      kind = decl;
    }
  }
}

bool SqliteArrowColumn::decided() const {
  return kind != AK_UNDECIDED;
}

ARROW_KIND SqliteArrowColumn::get_kind() const {
  return kind;
}

void SqliteArrowColumn::carry_over(ARROW_KIND kind_, bool wide_ints_) {
  if (kind_ != AK_UNDECIDED) {
    kind = kind_;
  }
  wide_ints = wide_ints || wide_ints_;
}

void SqliteArrowColumn::decide_from_row(bool has_row) {
  if (decided() || !has_row) {
    return;
  }
  kind = kind_from_column_type(sqlite3_column_type(stmt, j));
}

void SqliteArrowColumn::peek_value() {
  if (value_type == SQLITE_NULL) {
    return;
  }
  if (!decided()) {
    kind = kind_from_column_type(value_type);
  } else if (kind == AK_INT64 && value_type == SQLITE_FLOAT && !frozen) {
    kind = AK_DOUBLE;
  }
  if (kind == AK_INT64 && value_type == SQLITE_INTEGER) {
    note_integer(sqlite3_column_int64(stmt, j));
  }
}

void SqliteArrowColumn::decide_from_decltype() {
  if (decided()) {
    return;
  }
  kind = kind_from_decltype();
  if (kind == AK_UNDECIDED) {
    kind = AK_NA;
  }
}

void SqliteArrowColumn::freeze() {
  frozen = true;
}

void SqliteArrowColumn::reopen() {
  // The default path types an all-NULL column without a declared type as
  // logical, and decides it again in the next fetch
  if (!frozen && kind == AK_NA) {
    kind = AK_UNDECIDED;
  }
}

void SqliteArrowColumn::set_data_frame(bool data_frame_) {
  data_frame = data_frame_;
}

const char* SqliteArrowColumn::seconds_class() const {
  if (storage_kind() != AK_DOUBLE) {
    return "";
  }
  switch (kind) {
  case AK_TIME:
    return "hms";
  case AK_TIMESTAMP:
    return "POSIXct";
  default:
    return "";
  }
}

ARROW_KIND SqliteArrowColumn::storage_kind() const {
  if (data_frame && (kind == AK_TIME || kind == AK_TIMESTAMP)) {
    return AK_DOUBLE;
  }
  return kind;
}

void SqliteArrowColumn::set_schema(struct ArrowSchema* schema) const {
  set_type(schema, storage_kind());
  check_arrow(ArrowSchemaSetName(schema, name.c_str()), "Can't set Arrow name");
}

bool SqliteArrowColumn::wide_integers() const {
  return wide_ints;
}

void SqliteArrowColumn::set_type(struct ArrowSchema* schema, ARROW_KIND kind) {
  switch (kind) {
  case AK_NA:
    check_arrow(
      ArrowSchemaSetType(schema, NANOARROW_TYPE_NA),
      "Can't set Arrow type"
    );
    break;
  case AK_INT64:
    check_arrow(
      ArrowSchemaSetType(schema, NANOARROW_TYPE_INT64),
      "Can't set Arrow type"
    );
    break;
  case AK_DOUBLE:
    check_arrow(
      ArrowSchemaSetType(schema, NANOARROW_TYPE_DOUBLE),
      "Can't set Arrow type"
    );
    break;
  case AK_STRING:
    check_arrow(
      ArrowSchemaSetType(schema, NANOARROW_TYPE_STRING),
      "Can't set Arrow type"
    );
    break;
  case AK_BINARY:
    check_arrow(
      ArrowSchemaSetType(schema, NANOARROW_TYPE_BINARY),
      "Can't set Arrow type"
    );
    break;
  case AK_DATE:
    check_arrow(
      ArrowSchemaSetType(schema, NANOARROW_TYPE_DATE32),
      "Can't set Arrow type"
    );
    break;
  case AK_TIME:
    check_arrow(
      ArrowSchemaSetTypeDateTime(
        schema,
        NANOARROW_TYPE_TIME64,
        NANOARROW_TIME_UNIT_MICRO,
        NULL
      ),
      "Can't set Arrow type"
    );
    break;
  case AK_TIMESTAMP:
    check_arrow(
      ArrowSchemaSetTypeDateTime(
        schema,
        NANOARROW_TYPE_TIMESTAMP,
        NANOARROW_TIME_UNIT_MICRO,
        "UTC"
      ),
      "Can't set Arrow type"
    );
    break;
  case AK_UNDECIDED:
    throw std::runtime_error("Internal error: Arrow type not decided");
  }
}

// Chunk building //////////////////////////////////////////////////////////////

void SqliteArrowColumn::start_chunk() {
  array.reset();
  pending_nulls = 0;
  // The bytes of a row held back from the previous chunk are read again,
  // in case another fetch has converted the value since
  value_fetched = false;
  if (decided()) {
    init_array();
  }
}

void SqliteArrowColumn::read_row() {
  value_type = sqlite3_column_type(stmt, j);
  value_fetched = false;
}

int64_t SqliteArrowColumn::value_bytes() {
  if (value_type == SQLITE_NULL || (kind != AK_STRING && kind != AK_BINARY)) {
    return 0;
  }
  fetch_bytes();
  return value_size;
}

void SqliteArrowColumn::append_row() {
  const int column_type = value_type;

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
    check_arrow(
      ArrowArrayAppendNull(array.get(), 1),
      "Can't append to Arrow array"
    );
    return;
  }

  append_value(column_type);
}

void SqliteArrowColumn::finish_chunk(int64_t n, bool keep_open) {
  if (decided()) {
    return;
  }
  // Every value of this chunk was NULL
  if (keep_open) {
    // A later chunk of the same fetch decides, and conform_chunk() types this
    // one then
    array.reset();
    init_array(array.get(), AK_NA);
    array_kind = AK_NA;
  } else {
    // This is the last chance to decide
    decide_from_decltype();
    init_array();
  }
  check_arrow(
    ArrowArrayAppendNull(array.get(), n),
    "Can't append to Arrow array"
  );
  pending_nulls = 0;
}

ARROW_KIND SqliteArrowColumn::move_chunk_to(struct ArrowArray* out) {
  ArrowArrayMove(array.get(), out);
  return array_kind;
}

void SqliteArrowColumn::conform_chunk(
  struct ArrowArray* chunk,
  ARROW_KIND chunk_kind
) const {
  const ARROW_KIND target = storage_kind();
  if (chunk_kind == target) {
    return;
  }

  nanoarrow::UniqueArray out;
  init_array(out.get(), target);
  if (chunk_kind == AK_NA) {
    check_arrow(
      ArrowArrayAppendNull(out.get(), chunk->length),
      "Can't append to Arrow array"
    );
  } else if (chunk_kind == AK_INT64 && target == AK_DOUBLE) {
    append_ints_as_doubles(out.get(), chunk);
  } else {
    throw std::runtime_error(
      std::string("Internal error: can't convert an Arrow chunk of type ") +
      format_kind(chunk_kind) + " to " + format_kind(target)
    );
  }

  struct ArrowError error;
  ArrowErrorInit(&error);
  check_arrow(
    ArrowArrayFinishBuildingDefault(out.get(), &error),
    "Can't finish Arrow array",
    &error
  );

  chunk->release(chunk);
  ArrowArrayMove(out.get(), chunk);
}

int64_t SqliteArrowColumn::variable_bytes() {
  if (array->release == NULL) {
    return 0;
  }
  if (kind != AK_STRING && kind != AK_BINARY) {
    return 0;
  }
  return ArrowArrayBuffer(array.get(), 2)->size_bytes;
}

// Privates ////////////////////////////////////////////////////////////////////

// The default path stores integers as 32-bit until one needs more
void SqliteArrowColumn::note_integer(int64_t value) {
  if (value < -INT_MAX || value > INT_MAX) {
    wide_ints = true;
  }
}

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
    return AK_UNDECIDED;
  }

  if (with_alt_types) {
    if (boost::iequals(decl_type, "datetime") ||
        boost::iequals(decl_type, "timestamp")) {
      return AK_TIMESTAMP;
    } else if (boost::iequals(decl_type, "date")) {
      return AK_DATE;
    } else if (boost::iequals(decl_type, "time")) {
      return AK_TIME;
    }
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
  }

  return AK_UNDECIDED;
}

void SqliteArrowColumn::init_array() {
  array.reset();
  array_kind = storage_kind();
  init_array(array.get(), array_kind);
}

void SqliteArrowColumn::init_array(struct ArrowArray* out, ARROW_KIND kind) {
  nanoarrow::UniqueSchema schema;
  ArrowSchemaInit(schema.get());
  set_type(schema.get(), kind);

  struct ArrowError error;
  ArrowErrorInit(&error);
  check_arrow(
    ArrowArrayInitFromSchema(out, schema.get(), &error),
    "Can't allocate Arrow array",
    &error
  );
  check_arrow(ArrowArrayStartAppending(out), "Can't allocate Arrow array");
}

// Reads the bytes of a utf8 or binary value once per row
void SqliteArrowColumn::fetch_bytes() {
  if (value_fetched) {
    return;
  }
  // sqlite3_column_text() or sqlite3_column_blob() converts the value,
  // and must be called before sqlite3_column_bytes().
  // A blob keeps its bytes, also in a utf8 column: sqlite3_column_text()
  // would take them for text in the encoding of the database, and transcode
  // them in a UTF-16 one. Text and numbers are read as UTF-8 text, also in a
  // binary column, like the data frame path does it.
  if (value_type == SQLITE_BLOB) {
    value_data = sqlite3_column_blob(stmt, j);
  } else {
    value_data = sqlite3_column_text(stmt, j);
  }
  value_size = sqlite3_column_bytes(stmt, j);
  if (value_data == NULL) {
    // A zero-length blob, or out of memory while expanding a zeroblob(),
    // which fails the next step with SQLITE_NOMEM
    value_data = "";
    value_size = 0;
  }
  value_fetched = true;
}

void SqliteArrowColumn::append_value(int column_type) {
  switch (kind) {
  case AK_INT64:
    if (column_type == SQLITE_FLOAT && !frozen) {
      // The type is still open: a real value widens the column
      promote_to_double();
      append_value(column_type);
      return;
    }
    {
      int64_t value = sqlite3_column_int64(stmt, j);
      if (column_type == SQLITE_INTEGER) {
        note_integer(value);
      } else {
        warn_mixed(column_type);
      }
      check_arrow(
        ArrowArrayAppendInt(array.get(), value),
        "Can't append to Arrow array"
      );
      break;
    }

  case AK_DOUBLE:
    if (column_type != SQLITE_FLOAT && column_type != SQLITE_INTEGER) {
      warn_mixed(column_type);
    }
    check_arrow(
      ArrowArrayAppendDouble(array.get(), sqlite3_column_double(stmt, j)),
      "Can't append to Arrow array"
    );
    break;

  case AK_STRING:
    {
      if (column_type != SQLITE_TEXT) {
        warn_mixed(column_type);
      }
      fetch_bytes();
      const char* text = static_cast<const char*>(value_data);
      int64_t size = value_size;
      if (data_frame && column_type == SQLITE_TEXT) {
        // R strings end at the first NUL, like those of the default path,
        // which passes text through unchecked; an Arrow stream keeps all bytes
        const void* nul = memchr(text, '\0', static_cast<size_t>(size));
        if (nul != NULL) {
          size = static_cast<const char*>(nul) - text;
        }
      } else if ((column_type == SQLITE_TEXT || column_type == SQLITE_BLOB) &&
                 !is_utf8_text(text, static_cast<size_t>(size))) {
        // SQLite doesn't enforce UTF-8 for text, and keeps blobs as they are;
        // numbers convert to ASCII
        warn_invalid_utf8(column_type);
        check_arrow(
          ArrowArrayAppendNull(array.get(), 1),
          "Can't append to Arrow array"
        );
        break;
      }
      check_arrow(
        ArrowArrayAppendString(array.get(), arrow_string_view(text, size)),
        "Can't append to Arrow array"
      );
      break;
    }

  case AK_BINARY:
    {
      if (column_type != SQLITE_BLOB) {
        warn_mixed(column_type);
      }
      fetch_bytes();
      check_arrow(
        ArrowArrayAppendBytes(
          array.get(),
          arrow_buffer_view(value_data, value_size)
        ),
        "Can't append to Arrow array"
      );
      break;
    }

  case AK_DATE:
    {
      double days = source.fetch_date();
      if (ISNAN(days)) {
        check_arrow(
          ArrowArrayAppendNull(array.get(), 1),
          "Can't append to Arrow array"
        );
      } else {
        check_arrow(
          ArrowArrayAppendInt(array.get(), static_cast<int64_t>(days)),
          "Can't append to Arrow array"
        );
      }
      break;
    }

  case AK_TIME:
  case AK_TIMESTAMP:
    {
      double seconds =
        (kind == AK_TIME) ? source.fetch_time() : source.fetch_datetime_local();
      if (array_kind == AK_DOUBLE) {
        // For a data frame: the seconds of the default path, all of them
        if (ISNAN(seconds)) {
          check_arrow(
            ArrowArrayAppendNull(array.get(), 1),
            "Can't append to Arrow array"
          );
        } else {
          check_arrow(
            ArrowArrayAppendDouble(array.get(), seconds),
            "Can't append to Arrow array"
          );
        }
        break;
      }
      double micros = std::floor(seconds * 1e6 + 0.5);
      bool in_range;
      if (kind == AK_TIME) {
        // A time of day, [0, 86400) seconds: an hms value can hold any
        // duration, Arrow's time64 can't.
        // Rounding must not reach the end of the day.
        in_range = seconds >= 0 && seconds < 86400;
        micros = std::min(micros, 86400e6 - 1);
      } else {
        // int64 holds [-2^63, 2^63), both bounds exact as doubles: casting
        // anything outside, an infinity included, would be undefined
        in_range =
          micros >= -9223372036854775808.0 && micros < 9223372036854775808.0;
      }
      if (!ISNAN(seconds) && !in_range) {
        warn_out_of_range(column_type);
      }
      if (ISNAN(seconds) || !in_range) {
        check_arrow(
          ArrowArrayAppendNull(array.get(), 1),
          "Can't append to Arrow array"
        );
      } else {
        check_arrow(
          ArrowArrayAppendInt(array.get(), static_cast<int64_t>(micros)),
          "Can't append to Arrow array"
        );
      }
      break;
    }

  case AK_NA:
    warn_mixed(column_type);
    check_arrow(
      ArrowArrayAppendNull(array.get(), 1),
      "Can't append to Arrow array"
    );
    break;

  case AK_UNDECIDED:
    throw std::runtime_error("Internal error: Arrow type not decided");
  }
}

// Rebuilds the int64 array collected so far as a double array
void SqliteArrowColumn::promote_to_double() {
  nanoarrow::UniqueArray ints;
  ArrowArrayMove(array.get(), ints.get());

  kind = AK_DOUBLE;
  init_array();
  append_ints_as_doubles(array.get(), ints.get());
}

// Appends the values of `ints`, an int64 array built by nanoarrow, finished or
// not, to the double array `out`
void SqliteArrowColumn::append_ints_as_doubles(
  struct ArrowArray* out,
  struct ArrowArray* ints
) {
  int64_t n = ints->length;
  const int64_t* values =
    reinterpret_cast<const int64_t*>(ArrowArrayBuffer(ints, 1)->data);
  const struct ArrowBitmap* validity = ArrowArrayValidityBitmap(ints);
  bool has_nulls = validity->buffer.size_bytes > 0;

  for (int64_t i = 0; i < n; ++i) {
    if (has_nulls && !ArrowBitGet(validity->buffer.data, i)) {
      check_arrow(ArrowArrayAppendNull(out, 1), "Can't append to Arrow array");
    } else {
      check_arrow(
        ArrowArrayAppendDouble(out, static_cast<double>(values[i])),
        "Can't append to Arrow array"
      );
    }
  }
}

void SqliteArrowColumn::warn_mixed(int column_type) {
  if (warned) {
    return;
  }
  warned = true;

  std::stringstream ss;
  ss << "Column `" << name << "`: mixed type, Arrow type " << format_kind(kind)
     << " decided from the first values, coercing values of type "
     << format_column_type(column_type);
  cpp11::warning(ss.str());
  // A handler of the warning may have converted the value: read it again
  value_fetched = false;
}

void SqliteArrowColumn::warn_invalid_utf8(int column_type) {
  if (warned_utf8) {
    return;
  }
  warned_utf8 = true;

  std::stringstream ss;
  ss << "Column `" << name << "`: values of type "
     << format_column_type(column_type)
     << " that are not valid UTF-8, or hold a NUL byte, are NULL";
  cpp11::warning(ss.str());
}

void SqliteArrowColumn::warn_out_of_range(int column_type) {
  if (warned_range) {
    return;
  }
  warned_range = true;

  std::stringstream ss;
  ss << "Column `" << name << "`: values of type "
     << format_column_type(column_type) << " outside the range of Arrow type "
     << format_kind(kind) << " are NULL";
  cpp11::warning(ss.str());
}

const char* SqliteArrowColumn::format_kind(ARROW_KIND kind) {
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
  case AK_DATE:
    return "date32";
  case AK_TIME:
    return "time64";
  case AK_TIMESTAMP:
    return "timestamp";
  default:
    return "<undecided>";
  }
}

const char* SqliteArrowColumn::format_column_type(int column_type) {
  switch (column_type) {
  case SQLITE_INTEGER:
    return "integer";
  case SQLITE_FLOAT:
    return "real";
  case SQLITE_TEXT:
    return "string";
  case SQLITE_BLOB:
    return "blob";
  default:
    return "null";
  }
}
