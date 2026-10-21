#include "pch.h"
#include "SqliteParamSource.h"
#include "integer64.h"
#include <cmath>
#include <cstdlib>
#include <sstream>

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
    bind_parameter(stmt, static_cast<int>(j) + 1, params[j]);
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
      cpp11::stop("Can only bind lists of raw vectors (or NULL)");
    }
  } else {
    cpp11::stop(
      "Don't know how to handle parameter of type %s.",
      Rf_type2char(TYPEOF(value_))
    );
  }
}

// SqliteArrowParamSource //////////////////////////////////////////////////////

SqliteArrowParamSource::SqliteArrowParamSource(
  struct ArrowArrayStream* stream_,
  const std::vector<int>& param_indexes_
)
    : param_indexes(param_indexes_), i(0), n(0), exhausted(false) {
  // Take over the stream: the R object that provided it is released
  ArrowArrayStreamMove(stream_, stream.get());

  struct ArrowError error;
  ArrowErrorInit(&error);
  check_arrow(
    ArrowArrayStreamGetSchema(stream.get(), schema.get(), &error),
    "Can't read the schema of the parameters",
    &error
  );

  struct ArrowSchemaView struct_view;
  check_arrow(
    ArrowSchemaViewInit(&struct_view, schema.get(), &error),
    "Can't read the schema of the parameters",
    &error
  );
  if (struct_view.type != NANOARROW_TYPE_STRUCT) {
    throw std::runtime_error(
      "Parameters must be a struct array with one child per placeholder, not " +
      arrow_type_name(schema.get())
    );
  }

  int64_t n_children = schema->n_children;
  schema_views.resize(n_children);
  dictionary_views.resize(n_children);
  for (int64_t k = 0; k < n_children; ++k) {
    check_arrow(
      ArrowSchemaViewInit(&schema_views[k], schema->children[k], &error),
      "Can't read the schema of the parameters",
      &error
    );
    if (schema->children[k]->dictionary != NULL) {
      check_arrow(
        ArrowSchemaViewInit(
          &dictionary_views[k],
          schema->children[k]->dictionary,
          &error
        ),
        "Can't read the schema of the parameters",
        &error
      );
    }
  }

  for (size_t p = 0; p < param_indexes.size(); ++p) {
    if (param_indexes[p] < 0 || param_indexes[p] >= n_children) {
      throw std::runtime_error("Internal error: parameter index out of range");
    }
  }

  check_arrow(
    ArrowArrayViewInitFromSchema(view.get(), schema.get(), &error),
    "Can't read the schema of the parameters",
    &error
  );
}

bool SqliteArrowParamSource::bind_next_row(sqlite3_stmt* stmt) {
  while (i >= n) {
    if (exhausted || !next_batch()) {
      exhausted = true;
      return false;
    }
  }

  sqlite3_reset(stmt);
  sqlite3_clear_bindings(stmt);

  for (size_t p = 0; p < param_indexes.size(); ++p) {
    // sqlite parameters are 1-indexed
    bind_parameter(stmt, static_cast<int>(p) + 1, param_indexes[p], i);
  }

  ++i;
  return true;
}

bool SqliteArrowParamSource::next_batch() {
  struct ArrowError error;
  ArrowErrorInit(&error);

  array.reset();
  check_arrow(
    ArrowArrayStreamGetNext(stream.get(), array.get(), &error),
    "Can't read the parameters",
    &error
  );
  if (array->release == NULL) {
    // End of stream
    return false;
  }

  check_arrow(
    ArrowArrayViewSetArray(view.get(), array.get(), &error),
    "Invalid parameter array",
    &error
  );
  check_arrow(
    ArrowArrayViewValidate(
      view.get(),
      NANOARROW_VALIDATION_LEVEL_DEFAULT,
      &error
    ),
    "Invalid parameter array",
    &error
  );

  i = 0;
  n = array->length;
  return true;
}

void SqliteArrowParamSource::bind_parameter(
  sqlite3_stmt* stmt,
  int pos,
  int child,
  int64_t row
) {
  const struct ArrowArrayView* values = view->children[child];
  const struct ArrowSchemaView& schema_view = schema_views[child];

  if (ArrowArrayViewIsNull(values, row)) {
    sqlite3_bind_null(stmt, pos);
    return;
  }

  switch (schema_view.type) {
  case NANOARROW_TYPE_NA:
    sqlite3_bind_null(stmt, pos);
    break;

  case NANOARROW_TYPE_BOOL:
  case NANOARROW_TYPE_INT8:
  case NANOARROW_TYPE_UINT8:
  case NANOARROW_TYPE_INT16:
  case NANOARROW_TYPE_UINT16:
  case NANOARROW_TYPE_INT32:
  case NANOARROW_TYPE_UINT32:
  case NANOARROW_TYPE_INT64:
    sqlite3_bind_int64(stmt, pos, ArrowArrayViewGetIntUnsafe(values, row));
    break;

  case NANOARROW_TYPE_UINT64:
    {
      uint64_t value = ArrowArrayViewGetUIntUnsafe(values, row);
      if (value > static_cast<uint64_t>(INT64_MAX)) {
        std::stringstream ss;
        ss << "Can't bind value " << value
           << " outside the 64-bit signed integer range (parameter " << pos
           << ").";
        throw std::runtime_error(ss.str());
      }
      sqlite3_bind_int64(stmt, pos, static_cast<int64_t>(value));
      break;
    }

  case NANOARROW_TYPE_HALF_FLOAT:
  case NANOARROW_TYPE_FLOAT:
  case NANOARROW_TYPE_DOUBLE:
    sqlite3_bind_double(stmt, pos, ArrowArrayViewGetDoubleUnsafe(values, row));
    break;

  case NANOARROW_TYPE_DECIMAL32:
  case NANOARROW_TYPE_DECIMAL64:
  case NANOARROW_TYPE_DECIMAL128:
  case NANOARROW_TYPE_DECIMAL256:
    {
      // SQLite has no decimal type, the value is stored as a real number
      struct ArrowDecimal decimal;
      ArrowDecimalInit(
        &decimal,
        schema_view.decimal_bitwidth,
        schema_view.decimal_precision,
        schema_view.decimal_scale
      );
      ArrowArrayViewGetDecimalUnsafe(values, row, &decimal);
      nanoarrow::UniqueBuffer buffer;
      check_arrow(
        ArrowDecimalAppendStringToBuffer(&decimal, buffer.get()),
        "Can't format decimal parameter"
      );
      std::string text(
        reinterpret_cast<const char*>(buffer->data),
        buffer->size_bytes
      );
      sqlite3_bind_double(stmt, pos, std::strtod(text.c_str(), NULL));
      break;
    }

  case NANOARROW_TYPE_STRING:
  case NANOARROW_TYPE_LARGE_STRING:
  case NANOARROW_TYPE_STRING_VIEW:
    bind_string(stmt, pos, values, row);
    break;

  case NANOARROW_TYPE_DICTIONARY:
    {
      int64_t index = ArrowArrayViewGetIntUnsafe(values, row);
      const struct ArrowArrayView* dictionary = values->dictionary;
      if (ArrowArrayViewIsNull(dictionary, index)) {
        sqlite3_bind_null(stmt, pos);
        break;
      }
      switch (dictionary_views[child].type) {
      case NANOARROW_TYPE_STRING:
      case NANOARROW_TYPE_LARGE_STRING:
      case NANOARROW_TYPE_STRING_VIEW:
        bind_string(stmt, pos, dictionary, index);
        break;
      default:
        {
          std::stringstream ss;
          ss << "Can't bind Arrow type "
             << arrow_type_name(schema->children[child]) << " (parameter "
             << pos << ").";
          throw std::runtime_error(ss.str());
        }
      }
      break;
    }

  case NANOARROW_TYPE_BINARY:
  case NANOARROW_TYPE_LARGE_BINARY:
  case NANOARROW_TYPE_FIXED_SIZE_BINARY:
  case NANOARROW_TYPE_BINARY_VIEW:
    {
      struct ArrowBufferView bytes = ArrowArrayViewGetBytesUnsafe(values, row);
      sqlite3_bind_blob(
        stmt,
        pos,
        bytes.data.data,
        static_cast<int>(bytes.size_bytes),
        SQLITE_TRANSIENT
      );
      break;
    }

  case NANOARROW_TYPE_DATE32:
    // Dates are stored as days since the epoch, like the data frame path
    sqlite3_bind_double(
      stmt,
      pos,
      static_cast<double>(ArrowArrayViewGetIntUnsafe(values, row))
    );
    break;

  case NANOARROW_TYPE_DATE64:
    sqlite3_bind_double(
      stmt,
      pos,
      std::floor(
        static_cast<double>(ArrowArrayViewGetIntUnsafe(values, row)) /
        86400000.0
      )
    );
    break;

  case NANOARROW_TYPE_TIME32:
  case NANOARROW_TYPE_TIME64:
  case NANOARROW_TYPE_DURATION:
  case NANOARROW_TYPE_TIMESTAMP:
    // Times and timestamps are stored as (fractional) seconds, like the data
    // frame path; a timestamp is an instant, its time zone needs no conversion
    sqlite3_bind_double(
      stmt,
      pos,
      static_cast<double>(ArrowArrayViewGetIntUnsafe(values, row)) /
        units_per_second(schema_view.time_unit)
    );
    break;

  default:
    {
      std::stringstream ss;
      ss << "Can't bind Arrow type " << arrow_type_name(schema->children[child])
         << " (parameter " << pos << ").";
      throw std::runtime_error(ss.str());
    }
  }
}

void SqliteArrowParamSource::bind_string(
  sqlite3_stmt* stmt,
  int pos,
  const struct ArrowArrayView* values,
  int64_t row
) {
  struct ArrowStringView text = ArrowArrayViewGetStringUnsafe(values, row);
  sqlite3_bind_text(
    stmt,
    pos,
    text.data,
    static_cast<int>(text.size_bytes),
    SQLITE_TRANSIENT
  );
}

double SqliteArrowParamSource::units_per_second(enum ArrowTimeUnit unit) {
  switch (unit) {
  case NANOARROW_TIME_UNIT_SECOND:
    return 1.0;
  case NANOARROW_TIME_UNIT_MILLI:
    return 1e3;
  case NANOARROW_TIME_UNIT_MICRO:
    return 1e6;
  case NANOARROW_TIME_UNIT_NANO:
    return 1e9;
  }
  return 1.0;
}
