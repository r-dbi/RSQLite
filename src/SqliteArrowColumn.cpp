#include "pch.h"
#include "SqliteArrowColumn.h"
#include "affinity.h"
#include <cmath>

SqliteArrowColumn::SqliteArrowColumn(
  sqlite3_stmt* stmt_,
  const int j_,
  const std::string& name_
)
    : stmt(stmt_),
      j(j_),
      name(name_),
      kind(AK_UNDECIDED),
      frozen(false),
      pending_nulls(0) {}

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
  case AK_UNDECIDED:
  default:
    throw std::runtime_error("Internal error: Arrow type not decided");
  }

  check_arrow(ArrowSchemaSetType(schema, type), "Can't set Arrow type");
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

void SqliteArrowColumn::append_row() {
  const int column_type = sqlite3_column_type(stmt, j);
  if (column_type == SQLITE_TEXT || column_type == SQLITE_BLOB) {
    stop_unsupported();
  }

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

// Privates ////////////////////////////////////////////////////////////////////

ARROW_KIND SqliteArrowColumn::kind_from_column_type(int column_type) {
  switch (column_type) {
  case SQLITE_INTEGER:
    return AK_INT64;
  case SQLITE_FLOAT:
    return AK_DOUBLE;
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
  default:
    // TEXT or BLOB, not supported yet
    stop_unsupported();
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

void SqliteArrowColumn::append_value(int column_type) {
  switch (kind) {
  case AK_INT64:
    if (column_type == SQLITE_FLOAT) {
      if (!frozen) {
        // The type is still open: a real value widens the column
        promote_to_double();
        append_value(column_type);
        return;
      }
      // Truncated toward zero as SQLite does it, but NULL where SQLite would
      // saturate. Both bounds are exact as doubles, and casting a value
      // outside, an infinity included, would be undefined.
      double real = std::trunc(sqlite3_column_double(stmt, j));
      if (!(real >= -9223372036854775808.0 && real < 9223372036854775808.0)) {
        append_null();
        return;
      }
      check_arrow(
        ArrowArrayAppendInt(array.get(), static_cast<int64_t>(real)),
        "Can't append to Arrow array"
      );
      return;
    }
    check_arrow(
      ArrowArrayAppendInt(array.get(), sqlite3_column_int64(stmt, j)),
      "Can't append to Arrow array"
    );
    break;

  case AK_DOUBLE:
    check_arrow(
      ArrowArrayAppendDouble(array.get(), sqlite3_column_double(stmt, j)),
      "Can't append to Arrow array"
    );
    break;

  case AK_NA:
    append_null();
    break;

  case AK_UNDECIDED:
    throw std::runtime_error("Internal error: Arrow type not decided");
  }
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

  for (int64_t i = 0; i < n; ++i) {
    if (has_nulls && !ArrowBitGet(validity->buffer.data, i)) {
      append_null();
    } else {
      check_arrow(
        ArrowArrayAppendDouble(array.get(), static_cast<double>(values[i])),
        "Can't append to Arrow array"
      );
    }
  }
}

void SqliteArrowColumn::stop_unsupported() const {
  throw std::runtime_error(
    "Column `" + name +
    "`: Arrow arrays of text and blobs are not supported yet."
  );
}
