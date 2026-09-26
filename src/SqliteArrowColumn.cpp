#include "pch.h"
#include "SqliteArrowColumn.h"
#include "affinity.h"
#include "utf8.h"
#include <boost/algorithm/string/predicate.hpp>
#include <cmath>

using namespace cpp11::literals;

// Variable-width columns end a chunk once they hold this many bytes
static const int64_t ARROW_MAX_VAR_BYTES = int64_t(1) << 30;

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
      pending_nulls(0) {
  if (target.set) {
    // The type is final from the start
    kind = target.kind;
    unit = target.unit;
    timezone = target.timezone;
    frozen = true;
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

void SqliteArrowColumn::decide_from_row(bool has_row) {
  if (decided() || !has_row) {
    return;
  }
  kind = kind_from_column_type(sqlite3_column_type(stmt, j));
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

void SqliteArrowColumn::set_schema(struct ArrowSchema* schema) const {
  enum ArrowType type;
  switch (kind) {
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

  if (kind == AK_TIME32 || kind == AK_TIME64) {
    check_arrow(
      ArrowSchemaSetTypeDateTime(schema, type, unit, NULL),
      "Can't set Arrow type"
    );
  } else if (kind == AK_TIMESTAMP) {
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

  check_arrow(ArrowSchemaSetName(schema, name.c_str()), "Can't set Arrow name");
}

// Chunk building //////////////////////////////////////////////////////////////

void SqliteArrowColumn::start_chunk() {
  array.reset();
  pending_nulls = 0;
  if (decided()) {
    init_array();
  }
}

void SqliteArrowColumn::append_row(int64_t row) {
  int column_type = sqlite3_column_type(stmt, j);

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
  cpp11::writable::list out({ "column"_nm = cpp11::r_string(name),
                              "type"_nm = cpp11::r_string(format_kind(kind)),
                              "values"_nm = log.as_list() });
  log.clear();
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
//   into an integer type (truncated);
// - NULL, logged: a blob into a text type unless it is valid UTF-8, a number
//   outside the range of an integer type, a date or time that can't be parsed.
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
    if (column_type != SQLITE_FLOAT && column_type != SQLITE_INTEGER) {
      log.record(column_type, CR_CONVERTED, row);
    }
    check_arrow(
      ArrowArrayAppendDouble(array.get(), sqlite3_column_double(stmt, j)),
      "Can't append to Arrow array"
    );
    break;

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
    log.record(column_type, CR_CONVERTED, row);
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
  int64_t value = sqlite3_column_int64(stmt, j);
  if (!in_range(value)) {
    log.record(column_type, CR_OUT_OF_RANGE, row);
    append_null();
    return;
  }
  if (column_type != SQLITE_INTEGER) {
    log.record(column_type, CR_CONVERTED, row);
  }

  switch (kind) {
  case AK_BOOL:
    check_arrow(
      ArrowArrayAppendInt(array.get(), value != 0),
      "Can't append to Arrow array"
    );
    break;
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
  // sqlite3_column_text() must be called before sqlite3_column_bytes()
  const char* text =
    reinterpret_cast<const char*>(sqlite3_column_text(stmt, j));
  int size = sqlite3_column_bytes(stmt, j);
  if (column_type == SQLITE_BLOB) {
    // A blob keeps all its bytes, but only well-formed UTF-8 without NUL
    // bytes is text
    if (!rsqlite_is_utf8_string(text, static_cast<size_t>(size))) {
      log.record(column_type, CR_INVALID_UTF8, row);
      append_null();
      return;
    }
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
  const void* blob = sqlite3_column_blob(stmt, j);
  int size = sqlite3_column_bytes(stmt, j);
  check_arrow(
    ArrowArrayAppendBytes(array.get(), arrow_buffer_view(blob, size)),
    "Can't append to Arrow array"
  );
}

void SqliteArrowColumn::append_date(int column_type, int64_t row) {
  bool ok;
  double days = source.parse_date(ok);
  if (!ok || ISNAN(days)) {
    log.record(column_type, CR_UNPARSABLE, row);
    append_null();
    return;
  }
  int64_t value = static_cast<int64_t>(days);
  if (kind == AK_DATE64) {
    value *= INT64_C(86400000);
  }
  check_arrow(
    ArrowArrayAppendInt(array.get(), value),
    "Can't append to Arrow array"
  );
}

void SqliteArrowColumn::append_time(int column_type, int64_t row) {
  bool ok;
  double seconds = (kind == AK_TIMESTAMP) ? source.parse_datetime_local(ok)
                                          : source.parse_time(ok);
  if (!ok || ISNAN(seconds)) {
    log.record(column_type, CR_UNPARSABLE, row);
    append_null();
    return;
  }

  double scale;
  switch (unit) {
  case NANOARROW_TIME_UNIT_SECOND:
    scale = 1;
    break;
  case NANOARROW_TIME_UNIT_MILLI:
    scale = 1e3;
    break;
  case NANOARROW_TIME_UNIT_MICRO:
    scale = 1e6;
    break;
  default:
    scale = 1e9;
    break;
  }
  int64_t value = static_cast<int64_t>(std::floor(seconds * scale + 0.5));
  check_arrow(
    ArrowArrayAppendInt(array.get(), value),
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

  for (int64_t i = 0; i < n; ++i) {
    if (has_nulls && !ArrowBitGet(validity->buffer.data, i)) {
      check_arrow(
        ArrowArrayAppendNull(array.get(), 1),
        "Can't append to Arrow array"
      );
    } else {
      check_arrow(
        ArrowArrayAppendDouble(array.get(), static_cast<double>(values[i])),
        "Can't append to Arrow array"
      );
    }
  }
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
