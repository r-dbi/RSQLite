#include "pch.h"
#include "SqliteArrowColumn.h"
#include "affinity.h"
#include "utf8.h"
#include <boost/algorithm/string/predicate.hpp>
#include <boost/date_time/gregorian/gregorian.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <cfloat>
#include <climits>
#include <cmath>
#include <cstring>

using namespace cpp11::literals;

ArrowTarget ArrowTarget::from_schema(
  const struct ArrowSchema* schema,
  const std::string& name
) {
  struct ArrowError error;
  ArrowErrorInit(&error);
  struct ArrowSchemaView view;
  check_arrow(
    ArrowSchemaViewInit(&view, schema, &error),
    "Can't read Arrow schema",
    &error
  );

  ArrowTarget target;
  target.set = true;
  bool supported = (view.extension_name.data == NULL);
  switch (view.type) {
  case NANOARROW_TYPE_NA:
    target.kind = AK_NA;
    break;
  case NANOARROW_TYPE_BOOL:
    target.kind = AK_BOOL;
    break;
  case NANOARROW_TYPE_INT8:
    target.kind = AK_INT8;
    break;
  case NANOARROW_TYPE_INT16:
    target.kind = AK_INT16;
    break;
  case NANOARROW_TYPE_INT32:
    target.kind = AK_INT32;
    break;
  case NANOARROW_TYPE_INT64:
    target.kind = AK_INT64;
    break;
  case NANOARROW_TYPE_UINT8:
    target.kind = AK_UINT8;
    break;
  case NANOARROW_TYPE_UINT16:
    target.kind = AK_UINT16;
    break;
  case NANOARROW_TYPE_UINT32:
    target.kind = AK_UINT32;
    break;
  case NANOARROW_TYPE_UINT64:
    target.kind = AK_UINT64;
    break;
  case NANOARROW_TYPE_FLOAT:
    target.kind = AK_FLOAT;
    break;
  case NANOARROW_TYPE_DOUBLE:
    target.kind = AK_DOUBLE;
    break;
  case NANOARROW_TYPE_STRING:
    target.kind = AK_STRING;
    break;
  case NANOARROW_TYPE_LARGE_STRING:
    target.kind = AK_LARGE_STRING;
    break;
  case NANOARROW_TYPE_BINARY:
    target.kind = AK_BINARY;
    break;
  case NANOARROW_TYPE_LARGE_BINARY:
    target.kind = AK_LARGE_BINARY;
    break;
  case NANOARROW_TYPE_DATE32:
    target.kind = AK_DATE32;
    break;
  case NANOARROW_TYPE_DATE64:
    target.kind = AK_DATE64;
    break;
  case NANOARROW_TYPE_TIME32:
    target.kind = AK_TIME32;
    target.unit = view.time_unit;
    break;
  case NANOARROW_TYPE_TIME64:
    target.kind = AK_TIME64;
    target.unit = view.time_unit;
    break;
  case NANOARROW_TYPE_TIMESTAMP:
    target.kind = AK_TIMESTAMP;
    target.unit = view.time_unit;
    target.timezone = (view.timezone == NULL) ? "" : view.timezone;
    break;
  default:
    supported = false;
    break;
  }

  if (!supported) {
    throw std::runtime_error(
      "Can't fill a column of Arrow type " + arrow_type_name(schema) +
      " (column `" + name + "`)"
    );
  }
  return target;
}

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
  bool with_alt_types_,
  const ArrowTarget& target
)
    : stmt(stmt_),
      j(j_),
      name(name_),
      with_alt_types(with_alt_types_),
      source(stmt_, j_, with_alt_types_),
      kind(AK_UNDECIDED),
      unit(NANOARROW_TIME_UNIT_MICRO),
      timezone("UTC"),
      frozen(false),
      requested(false),
      data_frame(false),
      array_kind(AK_UNDECIDED),
      pending_nulls(0),
      wide_ints(false),
      unsigned_doubles(false),
      value_type(SQLITE_NULL),
      value_data(NULL),
      value_size(0),
      value_fetched(false) {
  if (target.set) {
    // The type is final from the start
    kind = target.kind;
    unit = target.unit;
    timezone = target.timezone;
    frozen = true;
    requested = true;
    return;
  }
  if (with_alt_types) {
    ARROW_KIND decl = kind_from_decltype();
    if (decl == AK_DATE32 || decl == AK_TIME64 || decl == AK_TIMESTAMP) {
      kind = decl;
    }
  }
}

bool SqliteArrowColumn::decided() const {
  return kind != AK_UNDECIDED;
}

bool SqliteArrowColumn::is_frozen() const {
  return frozen;
}

ARROW_KIND SqliteArrowColumn::get_kind() const {
  return kind;
}

void SqliteArrowColumn::carry_over(ARROW_KIND kind_, bool wide_ints_) {
  if (kind_ != AK_UNDECIDED && !requested) {
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
  int64_t value;
  if ((kind == AK_INT64 || kind == AK_UINT64) &&
      integer_value(value_type, value)) {
    note_integer(value);
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
  case AK_TIME64:
    return "hms";
  case AK_TIMESTAMP:
    return "POSIXct";
  default:
    return "";
  }
}

ARROW_KIND SqliteArrowColumn::storage_kind() const {
  // Decided from `extended_types`, these are a time64[us] or a timestamp[us]:
  // a requested type is built as requested
  if (data_frame && !requested && (kind == AK_TIME64 || kind == AK_TIMESTAMP)) {
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

void SqliteArrowColumn::set_type(
  struct ArrowSchema* schema,
  ARROW_KIND kind_
) const {
  enum ArrowType type;
  switch (kind_) {
  case AK_NA:
    type = NANOARROW_TYPE_NA;
    break;
  case AK_BOOL:
    type = NANOARROW_TYPE_BOOL;
    break;
  case AK_INT8:
    type = NANOARROW_TYPE_INT8;
    break;
  case AK_INT16:
    type = NANOARROW_TYPE_INT16;
    break;
  case AK_INT32:
    type = NANOARROW_TYPE_INT32;
    break;
  case AK_INT64:
    type = NANOARROW_TYPE_INT64;
    break;
  case AK_UINT8:
    type = NANOARROW_TYPE_UINT8;
    break;
  case AK_UINT16:
    type = NANOARROW_TYPE_UINT16;
    break;
  case AK_UINT32:
    type = NANOARROW_TYPE_UINT32;
    break;
  case AK_UINT64:
    type = NANOARROW_TYPE_UINT64;
    break;
  case AK_FLOAT:
    type = NANOARROW_TYPE_FLOAT;
    break;
  case AK_DOUBLE:
    type = NANOARROW_TYPE_DOUBLE;
    break;
  case AK_STRING:
    type = NANOARROW_TYPE_STRING;
    break;
  case AK_LARGE_STRING:
    type = NANOARROW_TYPE_LARGE_STRING;
    break;
  case AK_BINARY:
    type = NANOARROW_TYPE_BINARY;
    break;
  case AK_LARGE_BINARY:
    type = NANOARROW_TYPE_LARGE_BINARY;
    break;
  case AK_DATE32:
    type = NANOARROW_TYPE_DATE32;
    break;
  case AK_DATE64:
    type = NANOARROW_TYPE_DATE64;
    break;
  case AK_TIME32:
    type = NANOARROW_TYPE_TIME32;
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

  if (kind_ == AK_TIME32 || kind_ == AK_TIME64) {
    check_arrow(
      ArrowSchemaSetTypeDateTime(schema, type, unit, NULL),
      "Can't set Arrow type"
    );
  } else if (kind_ == AK_TIMESTAMP) {
    check_arrow(
      ArrowSchemaSetTypeDateTime(
        schema,
        type,
        unit,
        timezone.empty() ? NULL : timezone.c_str()
      ),
      "Can't set Arrow type"
    );
  } else {
    check_arrow(ArrowSchemaSetType(schema, type), "Can't set Arrow type");
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

void SqliteArrowColumn::append_row(int64_t row) {
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
    append_null();
    return;
  }

  append_value(column_type, row);
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

cpp11::sexp SqliteArrowColumn::coercions() {
  if (log.empty()) {
    return R_NilValue;
  }
  cpp11::writable::list out(
    { "column"_nm = cpp11::r_string(name),
      "type"_nm = cpp11::r_string(format_kind(kind)),
      "values"_nm = log.as_list() }
  );
  log.clear();
  return out;
}

void SqliteArrowColumn::discard_coercions() {
  log.clear();
}

// Privates ////////////////////////////////////////////////////////////////////

// The default path stores integers as 32-bit until one needs more
void SqliteArrowColumn::note_integer(int64_t value) {
  bool wide = (kind == AK_UINT64) ? static_cast<uint64_t>(value) > INT_MAX
                                  : (value < -INT_MAX || value > INT_MAX);
  if (wide) {
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
      return AK_DATE32;
    } else if (boost::iequals(decl_type, "time")) {
      return AK_TIME64;
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

void SqliteArrowColumn::init_array(
  struct ArrowArray* out,
  ARROW_KIND kind_
) const {
  nanoarrow::UniqueSchema schema;
  ArrowSchemaInit(schema.get());
  set_type(schema.get(), kind_);

  struct ArrowError error;
  ArrowErrorInit(&error);
  check_arrow(
    ArrowArrayInitFromSchema(out, schema.get(), &error),
    "Can't allocate Arrow array",
    &error
  );
  check_arrow(ArrowArrayStartAppending(out), "Can't allocate Arrow array");
}

// Reads the bytes of a value for a string or binary type once per row
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

void SqliteArrowColumn::append_null() {
  check_arrow(
    ArrowArrayAppendNull(array.get(), 1),
    "Can't append to Arrow array"
  );
}

// Values of another storage class than the column's type follow these rules,
// whether the type was requested or decided from the values:
// - silently: integers into a floating point type, integers and reals into a
//   text type (SQLite renders them), text into a binary type (its bytes);
// - converted by SQLite, logged: text and blobs into a numeric type, reals
//   into an integer type (truncated) or bool (true unless zero);
// - NULL, logged: a blob into a text type unless it is valid UTF-8, a value
//   outside the range of an integer, float, date, time or timestamp type, a
//   date or time that can't be parsed, any value into the null type.
void SqliteArrowColumn::append_value(int column_type, int64_t row) {
  switch (kind) {
  case AK_BOOL:
  case AK_INT8:
  case AK_INT16:
  case AK_INT32:
  case AK_INT64:
  case AK_UINT8:
  case AK_UINT16:
  case AK_UINT32:
  case AK_UINT64:
    append_integer(column_type, row);
    break;

  case AK_FLOAT:
  case AK_DOUBLE:
    {
      double value = sqlite3_column_double(stmt, j);
      if (kind == AK_FLOAT && std::isfinite(value) &&
          std::fabs(value) > FLT_MAX) {
        log.record(column_type, CR_OUT_OF_RANGE, row);
        append_null();
        break;
      }
      if (column_type != SQLITE_FLOAT && column_type != SQLITE_INTEGER) {
        log.record(column_type, CR_CONVERTED, row);
      }
      check_arrow(
        ArrowArrayAppendDouble(array.get(), value),
        "Can't append to Arrow array"
      );
      break;
    }

  case AK_STRING:
  case AK_LARGE_STRING:
    append_string(column_type, row);
    break;

  case AK_BINARY:
  case AK_LARGE_BINARY:
    append_binary(column_type, row);
    break;

  case AK_DATE32:
  case AK_DATE64:
    append_date(column_type, row);
    break;

  case AK_TIME32:
  case AK_TIME64:
  case AK_TIMESTAMP:
    append_time(column_type, row);
    break;

  case AK_NA:
    // Requested, or fixed by a first chunk of only NULL for an Arrow stream or
    // chunk and the data frame fetches after one: the null type drops the
    // values
    log.record(column_type, CR_NULL_TYPE, row);
    append_null();
    break;

  case AK_UNDECIDED:
  default:
    throw std::runtime_error("Internal error: Arrow type not decided");
  }
}

void SqliteArrowColumn::append_integer(int column_type, int64_t row) {
  if (kind == AK_INT64 && column_type == SQLITE_FLOAT && !frozen) {
    // The type is still open: a real value widens the column
    promote_to_double();
    append_value(column_type, row);
    return;
  }
  if (kind == AK_BOOL) {
    // A real is true unless it is zero, text and blobs are converted to an
    // integer by SQLite first
    if (column_type != SQLITE_INTEGER) {
      log.record(column_type, CR_CONVERTED, row);
    }
    bool truth = (column_type == SQLITE_FLOAT)
                   ? sqlite3_column_double(stmt, j) != 0.0
                   : sqlite3_column_int64(stmt, j) != 0;
    check_arrow(
      ArrowArrayAppendInt(array.get(), truth),
      "Can't append to Arrow array"
    );
    return;
  }

  int64_t value;
  if (!integer_value(column_type, value)) {
    log.record(column_type, CR_OUT_OF_RANGE, row);
    append_null();
    return;
  }
  if (column_type != SQLITE_INTEGER) {
    log.record(column_type, CR_CONVERTED, row);
  }
  if (kind == AK_INT64 || kind == AK_UINT64) {
    note_integer(value);
  }

  switch (kind) {
  case AK_UINT8:
  case AK_UINT16:
  case AK_UINT32:
  case AK_UINT64:
    check_arrow(
      ArrowArrayAppendUInt(array.get(), static_cast<uint64_t>(value)),
      "Can't append to Arrow array"
    );
    break;
  default:
    check_arrow(
      ArrowArrayAppendInt(array.get(), value),
      "Can't append to Arrow array"
    );
    break;
  }
}

// The integer at the start of `text`, read like SQLite reads text into an
// integer: after spaces and a sign, the digits up to the first other
// character. Its magnitude is exact up to 2^64 - 1, `overflow` is set beyond.
static uint64_t leading_integer(
  const char* text,
  int size,
  bool& negative,
  bool& overflow
) {
  const char* end = text + size;
  while (text < end && (*text == ' ' || (*text >= '\t' && *text <= '\r'))) {
    ++text;
  }
  negative = false;
  if (text < end && (*text == '-' || *text == '+')) {
    negative = (*text == '-');
    ++text;
  }
  uint64_t magnitude = 0;
  overflow = false;
  for (; text < end && *text >= '0' && *text <= '9'; ++text) {
    unsigned digit = static_cast<unsigned>(*text - '0');
    if (magnitude > (UINT64_MAX - digit) / 10) {
      overflow = true;
    } else {
      magnitude = magnitude * 10 + digit;
    }
  }
  return magnitude;
}

bool SqliteArrowColumn::integer_value(int column_type, int64_t& value) {
  if (column_type == SQLITE_FLOAT) {
    // Truncated toward zero, like SQLite does it, but not saturated
    double real = std::trunc(sqlite3_column_double(stmt, j));
    if (kind == AK_UINT64) {
      if (!(real >= 0 && real < 18446744073709551616.0)) {
        return false;
      }
      value = static_cast<int64_t>(static_cast<uint64_t>(real));
      return true;
    }
    if (!(real >= -9223372036854775808.0 && real < 9223372036854775808.0)) {
      return false;
    }
    value = static_cast<int64_t>(real);
    return in_range(value);
  }

  value = sqlite3_column_int64(stmt, j);
  if (column_type != SQLITE_INTEGER &&
      (value == INT64_MAX || value == INT64_MIN)) {
    // SQLite saturates the integer at the start of text or a blob
    const void* data =
      (column_type == SQLITE_TEXT)
        ? static_cast<const void*>(sqlite3_column_text(stmt, j))
        : sqlite3_column_blob(stmt, j);
    int size = sqlite3_column_bytes(stmt, j);
    bool negative;
    bool overflow;
    uint64_t magnitude =
      leading_integer(static_cast<const char*>(data), size, negative, overflow);
    if (overflow) {
      return false;
    }
    if (negative) {
      if (magnitude > UINT64_C(9223372036854775808)) {
        return false;
      }
    } else if (magnitude > static_cast<uint64_t>(INT64_MAX)) {
      if (kind != AK_UINT64) {
        return false;
      }
      value = static_cast<int64_t>(magnitude);
      return true;
    }
  }
  return in_range(value);
}

bool SqliteArrowColumn::in_range(int64_t value) const {
  switch (kind) {
  case AK_INT8:
    return value >= -128 && value <= 127;
  case AK_INT16:
    return value >= -32768 && value <= 32767;
  case AK_INT32:
    return value >= INT64_C(-2147483648) && value <= INT64_C(2147483647);
  case AK_UINT8:
    return value >= 0 && value <= 255;
  case AK_UINT16:
    return value >= 0 && value <= 65535;
  case AK_UINT32:
    return value >= 0 && value <= INT64_C(4294967295);
  case AK_UINT64:
    return value >= 0;
  default:
    return true;
  }
}

void SqliteArrowColumn::append_string(int column_type, int64_t row) {
  fetch_bytes();
  const char* text = static_cast<const char*>(value_data);
  int64_t size = value_size;
  if (data_frame && column_type == SQLITE_TEXT) {
    // R strings end at the first NUL, like those of the default path,
    // which passes text through unchecked; an Arrow stream checks it
    const void* nul = memchr(text, '\0', static_cast<size_t>(size));
    if (nul != NULL) {
      size = static_cast<const char*>(nul) - text;
    }
  } else if ((column_type == SQLITE_TEXT || column_type == SQLITE_BLOB) &&
             !is_utf8_text(text, static_cast<size_t>(size))) {
    // SQLite doesn't enforce UTF-8 for text, and a blob keeps all its bytes:
    // only well-formed UTF-8 without NUL bytes is text.
    // Numbers convert to ASCII.
    log.record(column_type, CR_INVALID_UTF8, row);
    append_null();
    return;
  }
  if (column_type == SQLITE_BLOB) {
    log.record(column_type, CR_CONVERTED, row);
  }
  check_arrow(
    ArrowArrayAppendString(array.get(), arrow_string_view(text, size)),
    "Can't append to Arrow array"
  );
}

void SqliteArrowColumn::append_binary(int column_type, int64_t row) {
  if (column_type == SQLITE_INTEGER || column_type == SQLITE_FLOAT) {
    log.record(column_type, CR_CONVERTED, row);
  }
  fetch_bytes();
  check_arrow(
    ArrowArrayAppendBytes(
      array.get(),
      arrow_buffer_view(value_data, value_size)
    ),
    "Can't append to Arrow array"
  );
}

void SqliteArrowColumn::append_date(int column_type, int64_t row) {
  // A number is a count of days, truncated toward zero. It is read here in
  // full: parse_date() reads 32 bits of it, like the default path does.
  int64_t days;
  bool fits = true;
  if (column_type == SQLITE_INTEGER) {
    days = sqlite3_column_int64(stmt, j);
  } else if (column_type == SQLITE_FLOAT) {
    double real = std::trunc(sqlite3_column_double(stmt, j));
    fits = real >= -9223372036854775808.0 && real < 9223372036854775808.0;
    days = fits ? static_cast<int64_t>(real) : 0;
  } else {
    bool ok;
    double parsed = source.parse_date(ok);
    if (!ok || ISNAN(parsed)) {
      log.record(column_type, CR_UNPARSABLE, row);
      append_null();
      return;
    }
    days = static_cast<int64_t>(parsed);
  }

  // The days of a date32, or their milliseconds for a date64, fit 32 or 64 bits
  const int64_t max_days =
    (kind == AK_DATE64) ? INT64_MAX / INT64_C(86400000) : INT32_MAX;
  const int64_t min_days =
    (kind == AK_DATE64) ? -(INT64_MAX / INT64_C(86400000)) : INT32_MIN;
  if (!fits || days < min_days || days > max_days) {
    log.record(column_type, CR_OUT_OF_RANGE, row);
    append_null();
    return;
  }

  int64_t value = days;
  if (kind == AK_DATE64) {
    value *= INT64_C(86400000);
  }
  check_arrow(
    ArrowArrayAppendInt(array.get(), value),
    "Can't append to Arrow array"
  );
}

// The ticks of a time unit per second
static int64_t ticks_per_second(enum ArrowTimeUnit unit) {
  switch (unit) {
  case NANOARROW_TIME_UNIT_SECOND:
    return 1;
  case NANOARROW_TIME_UNIT_MILLI:
    return 1000;
  case NANOARROW_TIME_UNIT_MICRO:
    return 1000000;
  default:
    return 1000000000;
  }
}

// `a * b` for a positive `b`, false if it doesn't fit 64 bits
static bool checked_multiply(int64_t a, int64_t b, int64_t& out) {
  if (a > INT64_MAX / b || a < INT64_MIN / b) {
    return false;
  }
  out = a * b;
  return true;
}

// `a / b` rounded toward negative infinity, for a positive `b`
static int64_t floor_divide(int64_t a, int64_t b) {
  int64_t q = a / b;
  if (a % b < 0) {
    --q;
  }
  return q;
}

bool SqliteArrowColumn::parse_micros(int column_type, int64_t& micros) const {
  namespace bp = boost::posix_time;
  namespace bg = boost::gregorian;
  namespace bd = boost::date_time;

  if (column_type != SQLITE_TEXT) {
    return false;
  }
  const char* text =
    reinterpret_cast<const char*>(sqlite3_column_text(stmt, j));
  try {
    if (kind == AK_TIMESTAMP) {
      bp::ptime time(bd::parse_delimited_time<bp::ptime>(text, ' '));
      micros = (time - bp::ptime(bg::date(1970, 1, 1), bp::seconds(0)))
                 .total_microseconds();
    } else {
      micros = bp::duration_from_string(text).total_microseconds();
    }
  } catch (...) {
    return false;
  }
  return true;
}

void SqliteArrowColumn::append_time(int column_type, int64_t row) {
  if (array_kind == AK_DOUBLE) {
    // For a data frame, unless the type was requested: the seconds of the
    // default path, all of them
    bool ok;
    double seconds = (kind == AK_TIMESTAMP) ? source.parse_datetime_local(ok)
                                            : source.parse_time(ok);
    if (!ok || ISNAN(seconds)) {
      log.record(column_type, CR_UNPARSABLE, row);
      append_null();
      return;
    }
    check_arrow(
      ArrowArrayAppendDouble(array.get(), seconds),
      "Can't append to Arrow array"
    );
    return;
  }

  const int64_t per_second = ticks_per_second(unit);
  int64_t value = 0;
  bool fits;
  // Whether a time is before the end of the day before it is rounded
  bool before_day_end = false;

  if (column_type == SQLITE_INTEGER) {
    // Whole seconds, scaled exactly
    fits = checked_multiply(sqlite3_column_int64(stmt, j), per_second, value);
  } else if (column_type == SQLITE_FLOAT) {
    // Seconds, rounded to the nearest tick in double precision
    double seconds = sqlite3_column_double(stmt, j);
    double ticks = std::floor(seconds * per_second + 0.5);
    fits = ticks >= -9223372036854775808.0 && ticks < 9223372036854775808.0;
    if (fits) {
      value = static_cast<int64_t>(ticks);
    }
    before_day_end = seconds < 86400;
  } else {
    // Text, parsed to whole microseconds and rounded to the nearest tick
    int64_t micros;
    if (!parse_micros(column_type, micros)) {
      log.record(column_type, CR_UNPARSABLE, row);
      append_null();
      return;
    }
    if (per_second >= 1000000) {
      fits = checked_multiply(micros, per_second / 1000000, value);
    } else {
      const int64_t per_tick = 1000000 / per_second;
      fits = micros <= INT64_MAX - per_tick / 2;
      if (fits) {
        value = floor_divide(micros + per_tick / 2, per_tick);
      }
    }
    before_day_end = micros < INT64_C(86400000000);
  }

  if (fits && kind != AK_TIMESTAMP) {
    // A time of day, which rounding doesn't take past its last tick
    const int64_t day = 86400 * per_second;
    if (value == day && before_day_end) {
      value = day - 1;
    }
    fits = value >= 0 && value < day;
  }
  if (!fits) {
    log.record(column_type, CR_OUT_OF_RANGE, row);
    append_null();
    return;
  }
  check_arrow(
    ArrowArrayAppendInt(array.get(), value),
    "Can't append to Arrow array"
  );
}

// Rebuilds the int64 array collected so far as a double array
void SqliteArrowColumn::promote_to_double() {
  nanoarrow::UniqueArray ints;
  ArrowArrayMove(array.get(), ints.get());

  kind = AK_DOUBLE;
  init_array();
  append_ints_as_doubles(array.get(), ints.get());
}

// Appends the values of `ints`, an int64 or for `is_unsigned` a uint64 array
// built by nanoarrow, finished or not, to the double array `out`
void SqliteArrowColumn::append_ints_as_doubles(
  struct ArrowArray* out,
  struct ArrowArray* ints,
  bool is_unsigned
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
      double value = is_unsigned
                       ? static_cast<double>(static_cast<uint64_t>(values[i]))
                       : static_cast<double>(values[i]);
      check_arrow(
        ArrowArrayAppendDouble(out, value),
        "Can't append to Arrow array"
      );
    }
  }
}

bool SqliteArrowColumn::conform_unsigned(
  std::vector<nanoarrow::UniqueArray>& chunks,
  size_t j
) {
  if (kind != AK_UINT64) {
    return false;
  }

  for (size_t i = 0; i < chunks.size() && !unsigned_doubles; ++i) {
    struct ArrowArray* values = chunks[i]->children[j];
    const uint64_t* data =
      reinterpret_cast<const uint64_t*>(ArrowArrayBuffer(values, 1)->data);
    const struct ArrowBitmap* validity = ArrowArrayValidityBitmap(values);
    bool has_nulls = validity->buffer.size_bytes > 0;
    for (int64_t k = 0; k < values->length; ++k) {
      if ((!has_nulls || ArrowBitGet(validity->buffer.data, k)) &&
          data[k] > static_cast<uint64_t>(INT64_MAX)) {
        unsigned_doubles = true;
        break;
      }
    }
  }
  if (!unsigned_doubles) {
    return false;
  }

  for (size_t i = 0; i < chunks.size(); ++i) {
    struct ArrowArray* values = chunks[i]->children[j];
    nanoarrow::UniqueArray out;
    init_array(out.get(), AK_DOUBLE);
    append_ints_as_doubles(out.get(), values, true);

    struct ArrowError error;
    ArrowErrorInit(&error);
    check_arrow(
      ArrowArrayFinishBuildingDefault(out.get(), &error),
      "Can't finish Arrow array",
      &error
    );
    values->release(values);
    ArrowArrayMove(out.get(), values);
  }
  return true;
}

const char* SqliteArrowColumn::format_kind(ARROW_KIND kind) {
  switch (kind) {
  case AK_NA:
    return "null";
  case AK_BOOL:
    return "bool";
  case AK_INT8:
    return "int8";
  case AK_INT16:
    return "int16";
  case AK_INT32:
    return "int32";
  case AK_INT64:
    return "int64";
  case AK_UINT8:
    return "uint8";
  case AK_UINT16:
    return "uint16";
  case AK_UINT32:
    return "uint32";
  case AK_UINT64:
    return "uint64";
  case AK_FLOAT:
    return "float";
  case AK_DOUBLE:
    return "double";
  case AK_STRING:
    return "utf8";
  case AK_LARGE_STRING:
    return "large_utf8";
  case AK_BINARY:
    return "binary";
  case AK_LARGE_BINARY:
    return "large_binary";
  case AK_DATE32:
    return "date32";
  case AK_DATE64:
    return "date64";
  case AK_TIME32:
    return "time32";
  case AK_TIME64:
    return "time64";
  case AK_TIMESTAMP:
    return "timestamp";
  default:
    return "<undecided>";
  }
}
