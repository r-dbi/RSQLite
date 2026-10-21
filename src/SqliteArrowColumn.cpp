#include "pch.h"
#include "SqliteArrowColumn.h"
#include "affinity.h"
#include <boost/algorithm/string/predicate.hpp>
#include <cmath>
#include <sstream>

// Variable-width columns end a chunk once they hold this many bytes
static const int64_t ARROW_MAX_VAR_BYTES = int64_t(1) << 30;

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
      pending_nulls(0),
      warned(false) {
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
    check_arrow(
      ArrowArrayAppendNull(array.get(), 1),
      "Can't append to Arrow array"
    );
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
    if (column_type == SQLITE_FLOAT && !frozen) {
      // The type is still open: a real value widens the column
      promote_to_double();
      append_value(column_type);
      return;
    }
    if (column_type != SQLITE_INTEGER) {
      warn_mixed(column_type);
    }
    check_arrow(
      ArrowArrayAppendInt(array.get(), sqlite3_column_int64(stmt, j)),
      "Can't append to Arrow array"
    );
    break;

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
      // sqlite3_column_text() must be called before sqlite3_column_bytes()
      const char* text =
        reinterpret_cast<const char*>(sqlite3_column_text(stmt, j));
      int size = sqlite3_column_bytes(stmt, j);
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
      const void* blob = sqlite3_column_blob(stmt, j);
      int size = sqlite3_column_bytes(stmt, j);
      check_arrow(
        ArrowArrayAppendBytes(array.get(), arrow_buffer_view(blob, size)),
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
      if (ISNAN(seconds)) {
        check_arrow(
          ArrowArrayAppendNull(array.get(), 1),
          "Can't append to Arrow array"
        );
      } else {
        int64_t micros = static_cast<int64_t>(std::floor(seconds * 1e6 + 0.5));
        check_arrow(
          ArrowArrayAppendInt(array.get(), micros),
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
