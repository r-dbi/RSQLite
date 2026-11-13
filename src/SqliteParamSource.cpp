#include "pch.h"
#include "SqliteParamSource.h"
#include "integer64.h"
#include <cstring>
#include <stdexcept>

SqliteParamSource::~SqliteParamSource() {}

// SqliteListParamSource ///////////////////////////////////////////////////////

SqliteListParamSource::SqliteListParamSource(const cpp11::list& params_)
    : params(params_), i(0), n(0) {
  if (params.size() > 0) {
    n = Rf_xlength(params[0]);
  }
}

bool SqliteListParamSource::bind_next_row(sqlite3_stmt* stmt) {
  if (i >= n) {
    return false;
  }

  sqlite3_reset(stmt);
  sqlite3_clear_bindings(stmt);

  for (R_xlen_t j = 0; j < params.size(); ++j) {
    // sqlite parameters are 1-indexed
    bind_parameter(stmt, (int)j + 1, params[j]);
  }

  ++i;
  return true;
}

void SqliteListParamSource::bind_parameter(
  sqlite3_stmt* stmt,
  int pos,
  SEXP value_
) const {
  if (TYPEOF(value_) == LGLSXP) {
    int value = LOGICAL(value_)[i];
    if (value == NA_LOGICAL) {
      sqlite3_bind_null(stmt, pos);
    } else {
      sqlite3_bind_int(stmt, pos, value);
    }
  } else if (TYPEOF(value_) == INT64SXP && Rf_inherits(value_, "integer64")) {
    int64_t value = INTEGER64(value_)[i];
    if (value == NA_INTEGER64) {
      sqlite3_bind_null(stmt, pos);
    } else {
      sqlite3_bind_int64(stmt, pos, value);
    }
  } else if (TYPEOF(value_) == INTSXP) {
    int value = INTEGER(value_)[i];
    if (value == NA_INTEGER) {
      sqlite3_bind_null(stmt, pos);
    } else {
      sqlite3_bind_int(stmt, pos, value);
    }
  } else if (TYPEOF(value_) == REALSXP) {
    double value = REAL(value_)[i];
    if (value == NA_REAL) {
      sqlite3_bind_null(stmt, pos);
    } else {
      sqlite3_bind_double(stmt, pos, value);
    }
  } else if (TYPEOF(value_) == STRSXP) {
    SEXP value = STRING_ELT(value_, i);
    if (value == NA_STRING) {
      sqlite3_bind_null(stmt, pos);
    } else {
      sqlite3_bind_text(stmt, pos, CHAR(value), -1, SQLITE_TRANSIENT);
    }
  } else if (TYPEOF(value_) == VECSXP) {
    SEXP value = VECTOR_ELT(value_, i);
    if (TYPEOF(value) == NILSXP) {
      sqlite3_bind_null(stmt, pos);
    } else if (TYPEOF(value) == RAWSXP) {
      sqlite3_bind_blob(
        stmt,
        pos,
        RAW(value),
        Rf_length(value),
        SQLITE_TRANSIENT
      );
    } else {
      throw std::runtime_error("Can only bind lists of raw vectors (or NULL)");
    }
  } else {
    throw std::runtime_error(
      std::string("Don't know how to handle parameter of type ") +
      Rf_type2char(TYPEOF(value_)) + "."
    );
  }
}

// SqliteArrowParamSource //////////////////////////////////////////////////////

namespace {

// Calls `callback` of `stream` and throws its error as a std::runtime_error,
// prefixed with `what`.
// An R error that leaves the callback by a longjmp,
// as in a stream implemented in R,
// becomes a cpp11::unwind_exception, which unwinds the C++ frames,
// and continues at the entry point.
// A stream of RSQLite protects its own callbacks with cpp11 in turn:
// cpp11 >= 0.4.6 protects nested calls, see LinkingTo in DESCRIPTION.
template <typename Callback>
void call_stream(
  struct ArrowArrayStream* stream,
  Callback callback,
  const char* what
) {
  int code = 0;
  const char* message = NULL;
  cpp11::unwind_protect([&] {
    code = callback();
    if (code != 0) {
      message = stream->get_last_error(stream);
    }
  });
  if (code != 0) {
    throw std::runtime_error(
      std::string(what) + ": " + (message != NULL ? message : strerror(code))
    );
  }
}

// The types that map to a storage class of SQLite
bool can_bind(enum ArrowType type) {
  switch (type) {
  case NANOARROW_TYPE_NA:
  case NANOARROW_TYPE_BOOL:
  case NANOARROW_TYPE_INT8:
  case NANOARROW_TYPE_UINT8:
  case NANOARROW_TYPE_INT16:
  case NANOARROW_TYPE_UINT16:
  case NANOARROW_TYPE_INT32:
  case NANOARROW_TYPE_UINT32:
  case NANOARROW_TYPE_INT64:
  case NANOARROW_TYPE_UINT64:
  case NANOARROW_TYPE_HALF_FLOAT:
  case NANOARROW_TYPE_FLOAT:
  case NANOARROW_TYPE_DOUBLE:
  case NANOARROW_TYPE_STRING:
  case NANOARROW_TYPE_LARGE_STRING:
  case NANOARROW_TYPE_BINARY:
  case NANOARROW_TYPE_LARGE_BINARY:
  case NANOARROW_TYPE_DATE32:
  case NANOARROW_TYPE_TIME32:
  case NANOARROW_TYPE_TIME64:
  case NANOARROW_TYPE_TIMESTAMP:
  case NANOARROW_TYPE_DURATION:
    return true;
  default:
    return false;
  }
}

double units_per_second(enum ArrowTimeUnit unit) {
  switch (unit) {
  case NANOARROW_TIME_UNIT_MILLI:
    return 1e3;
  case NANOARROW_TIME_UNIT_MICRO:
    return 1e6;
  case NANOARROW_TIME_UNIT_NANO:
    return 1e9;
  case NANOARROW_TIME_UNIT_SECOND:
  default:
    return 1.0;
  }
}

void check_bind(int rc, int pos) {
  if (rc != SQLITE_OK) {
    throw std::runtime_error(
      "Can't bind parameter " + std::to_string(pos) + ": " +
      sqlite3_errstr(rc) + "."
    );
  }
}

}  // namespace

SqliteArrowParamSource::SqliteArrowParamSource(
  struct ArrowArrayStream* stream_,
  const std::vector<int>& indexes_
)
    : indexes(indexes_), i(0), rows(0) {
  call_stream(
    stream_,
    [&] { return stream_->get_schema(stream_, schema.get()); },
    "Can't read the schema of the Arrow parameters"
  );

  struct ArrowError error;
  ArrowErrorInit(&error);
  for (size_t k = 0; k < indexes.size(); ++k) {
    if (indexes[k] < 0 || indexes[k] >= schema->n_children) {
      throw std::runtime_error("Internal error: parameter index out of range");
    }
    const struct ArrowSchema* child = schema->children[indexes[k]];
    struct ArrowSchemaView type;
    check_arrow(
      ArrowSchemaViewInit(&type, child, &error),
      "Can't read the schema of the Arrow parameters",
      &error
    );
    // A dictionary of values of a type that can be bound,
    // with indices of any integer type
    if (type.type == NANOARROW_TYPE_DICTIONARY) {
      check_arrow(
        ArrowSchemaViewInit(&type, child->dictionary, &error),
        "Can't read the schema of the Arrow parameters",
        &error
      );
    }
    if (!can_bind(type.type)) {
      char name[256];
      ArrowSchemaToString(child, name, sizeof(name), 1);
      throw std::runtime_error(
        "Can't bind parameter " + std::to_string(k + 1) + " of Arrow type " +
        name + "."
      );
    }
    types.push_back(type);
  }
  check_arrow(
    ArrowArrayViewInitFromSchema(view.get(), schema.get(), &error),
    "Can't read the schema of the Arrow parameters",
    &error
  );

  ArrowArrayStreamMove(stream_, stream.get());
}

bool SqliteArrowParamSource::bind_next_row(sqlite3_stmt* stmt) {
  // Empty arrays bind nothing
  while (array->release == NULL || i >= array->length) {
    if (!next_array()) {
      return false;
    }
  }

  sqlite3_reset(stmt);
  sqlite3_clear_bindings(stmt);
  ++rows;

  // A null struct row binds NULL to every placeholder,
  // as sqlite3_clear_bindings() left them
  if (!ArrowArrayViewIsNull(view.get(), i)) {
    // The offset of the struct array applies to its children,
    // whose views add only their own offsets
    const int64_t row = view->offset + i;
    for (size_t k = 0; k < indexes.size(); ++k) {
      // sqlite parameters are 1-indexed
      bind_parameter(stmt, static_cast<int>(k) + 1, row);
    }
  }

  ++i;
  return true;
}

const struct ArrowArrayStream* SqliteArrowParamSource::get_stream() const {
  return stream.get();
}

// Reads the next array of the stream, or returns false at its end
bool SqliteArrowParamSource::next_array() {
  array.reset();
  i = 0;
  struct ArrowArrayStream* s = stream.get();
  call_stream(
    s,
    [&] { return s->get_next(s, array.get()); },
    "Can't read the Arrow parameters"
  );
  if (array->release == NULL) {
    return false;
  }

  struct ArrowError error;
  ArrowErrorInit(&error);
  check_arrow(
    ArrowArrayViewSetArray(view.get(), array.get(), &error),
    "Invalid Arrow parameters",
    &error
  );
  return true;
}

// Binds the value of `row` of the child of placeholder `pos`;
// a null leaves the NULL of sqlite3_clear_bindings()
void SqliteArrowParamSource::bind_parameter(
  sqlite3_stmt* stmt,
  int pos,
  int64_t row
) const {
  const struct ArrowSchemaView& type = types[pos - 1];
  const struct ArrowArrayView* values = view->children[indexes[pos - 1]];
  if (type.type == NANOARROW_TYPE_NA || ArrowArrayViewIsNull(values, row)) {
    return;
  }
  // A dictionary binds the value of its index, or NULL for a null value.
  // Validation of the array doesn't look at the indices.
  if (values->dictionary != NULL) {
    const int64_t index = ArrowArrayViewGetIntUnsafe(values, row);
    if (index < 0 || index >= values->dictionary->length) {
      const std::string text = values->storage_type == NANOARROW_TYPE_UINT64
        ? std::to_string(ArrowArrayViewGetUIntUnsafe(values, row))
        : std::to_string(index);
      throw std::runtime_error(
        "Can't bind the dictionary index " + text + where(pos) +
        ", out of range for " + std::to_string(values->dictionary->length) +
        " values."
      );
    }
    values = values->dictionary;
    row = index;
    if (ArrowArrayViewIsNull(values, row)) {
      return;
    }
  }

  int rc = SQLITE_OK;
  switch (type.type) {
  case NANOARROW_TYPE_UINT64:
    {
      uint64_t value = ArrowArrayViewGetUIntUnsafe(values, row);
      if (value > static_cast<uint64_t>(INT64_MAX)) {
        throw std::runtime_error(
          "Can't bind the value " + std::to_string(value) + " of parameter " +
          std::to_string(pos) + " beyond the range of a signed 64-bit integer."
        );
      }
      rc = sqlite3_bind_int64(stmt, pos, static_cast<sqlite3_int64>(value));
      break;
    }
  case NANOARROW_TYPE_HALF_FLOAT:
  case NANOARROW_TYPE_FLOAT:
  case NANOARROW_TYPE_DOUBLE:
    rc = sqlite3_bind_double(
      stmt,
      pos,
      ArrowArrayViewGetDoubleUnsafe(values, row)
    );
    break;
  case NANOARROW_TYPE_STRING:
  case NANOARROW_TYPE_LARGE_STRING:
    {
      struct ArrowBufferView text = value_bytes(stmt, pos, values, row);
      // An empty value may have no data, which would bind NULL
      rc = sqlite3_bind_text64(
        stmt,
        pos,
        text.size_bytes > 0 ? text.data.as_char : "",
        static_cast<sqlite3_uint64>(text.size_bytes),
        SQLITE_TRANSIENT,
        SQLITE_UTF8
      );
      break;
    }
  case NANOARROW_TYPE_BINARY:
  case NANOARROW_TYPE_LARGE_BINARY:
    {
      struct ArrowBufferView bytes = value_bytes(stmt, pos, values, row);
      if (bytes.size_bytes == 0) {
        rc = sqlite3_bind_zeroblob(stmt, pos, 0);
      } else {
        rc = sqlite3_bind_blob64(
          stmt,
          pos,
          bytes.data.data,
          static_cast<sqlite3_uint64>(bytes.size_bytes),
          SQLITE_TRANSIENT
        );
      }
      break;
    }
  case NANOARROW_TYPE_DATE32:
    // Days since the epoch, as dbBind() binds a Date
    rc = sqlite3_bind_double(
      stmt,
      pos,
      static_cast<double>(ArrowArrayViewGetIntUnsafe(values, row))
    );
    break;
  case NANOARROW_TYPE_TIME32:
  case NANOARROW_TYPE_TIME64:
  case NANOARROW_TYPE_TIMESTAMP:
  case NANOARROW_TYPE_DURATION:
    // Seconds since midnight or the epoch, or of a duration,
    // as dbBind() binds hms, POSIXct and difftime in seconds;
    // a timestamp is an instant, whatever its time zone
    rc = sqlite3_bind_double(
      stmt,
      pos,
      static_cast<double>(ArrowArrayViewGetIntUnsafe(values, row)) /
        units_per_second(type.time_unit)
    );
    break;
  default:
    // Booleans and the other integers, see can_bind()
    rc = sqlite3_bind_int64(stmt, pos, ArrowArrayViewGetIntUnsafe(values, row));
    break;
  }
  check_bind(rc, pos);
}

// The bytes of value `row` of a string or binary array.
// Validation of the array checks only its first and last offsets:
// a value whose offsets are negative, decreasing or beyond the data
// fails here rather than read out of bounds.
// The C data interface has no buffer sizes,
// so the last offset gives the size of the data.
// A value longer than SQLite's length limit fails with its size and row,
// before its data is read;
// sqlite3_bind_text64() and sqlite3_bind_blob64() would refuse it too.
struct ArrowBufferView SqliteArrowParamSource::value_bytes(
  sqlite3_stmt* stmt,
  int pos,
  const struct ArrowArrayView* values,
  int64_t row
) const {
  const int64_t k = values->offset + row;
  int64_t start, end;
  if (values->layout.element_size_bits[1] == 64) {
    start = values->buffer_views[1].data.as_int64[k];
    end = values->buffer_views[1].data.as_int64[k + 1];
  } else {
    start = values->buffer_views[1].data.as_int32[k];
    end = values->buffer_views[1].data.as_int32[k + 1];
  }
  if (start < 0 || end < start || end > values->buffer_views[2].size_bytes) {
    throw std::runtime_error(
      "Invalid Arrow parameters: the offsets" + where(pos) +
      " point outside its data."
    );
  }

  const int64_t limit =
    sqlite3_limit(sqlite3_db_handle(stmt), SQLITE_LIMIT_LENGTH, -1);
  if (end - start > limit) {
    throw std::runtime_error(
      "Can't bind the value of " + std::to_string(end - start) + " bytes" +
      where(pos) + ", beyond SQLite's length limit of " +
      std::to_string(limit) + " bytes."
    );
  }

  struct ArrowBufferView out;
  out.data.as_uint8 = values->buffer_views[2].data.as_uint8 + start;
  out.size_bytes = end - start;
  return out;
}

// Names the parameter and the row being bound, for messages
std::string SqliteArrowParamSource::where(int pos) const {
  return " of parameter " + std::to_string(pos) + " in row " +
    std::to_string(rows);
}
