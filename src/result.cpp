#include "pch.h"
#include <vector>
#include <climits>
#include "integer64.h"
#include "RSQLite_types.h"
#include "DbArrow.h"
#include "DbArrowStream.h"
// After DbArrow.h, so that the Arrow C structs are defined once
#include <nanoarrow/r.h>

// #include "DbResult.h"

[[cpp11::register]]
cpp11::external_pointer<DbResultPtr> result_create(
  cpp11::external_pointer<DbConnectionPtr> con,
  std::string sql
) {
  (*con)->check_connection();
  DbResultPtr* res =
    new DbResultPtr(SqliteResult::create_and_send_query(*con, sql));
  return cpp11::external_pointer<DbResultPtr>(res, true);
}

[[cpp11::register]]
void result_release(cpp11::external_pointer<DbResultPtr> res) {
  res.reset();
}

[[cpp11::register]]
bool result_valid(cpp11::external_pointer<DbResultPtr> res_) {
  DbResultPtr* res = res_.get();
  return res != NULL && res->get() != NULL && (*res)->is_active();
}

[[cpp11::register]]
cpp11::list result_fetch(DbResult* res, const int n) {
  return res->fetch(n);
}

[[cpp11::register]]
void result_bind(DbResult* res, cpp11::list params) {
  res->bind(params);
}

[[cpp11::register]]
bool result_has_completed(DbResult* res) {
  return res->complete();
}

[[cpp11::register]]
int result_rows_fetched(DbResult* res) {
  return res->n_rows_fetched();
}

[[cpp11::register]]
int result_rows_affected(DbResult* res) {
  return res->n_rows_affected();
}

[[cpp11::register]]
cpp11::list result_column_info(DbResult* res) {
  return res->get_column_info();
}

[[cpp11::register]]
cpp11::strings result_column_names(DbResult* res) {
  return res->get_column_names();
}

[[cpp11::register]]
cpp11::strings result_get_placeholder_names(SqliteResult* res) {
  return res->get_placeholder_names();
}

// Arrow ///////////////////////////////////////////////////////////////////////

// Requests the Arrow types of the children of `schema` for the result columns
// at the zero-based `positions`, before the first row is fetched
[[cpp11::register]]
void result_set_arrow_schema(
  DbResult* res,
  cpp11::sexp schema,
  cpp11::integers positions
) {
  if (!Rf_inherits(schema, "nanoarrow_schema")) {
    cpp11::stop("`schema` must be a nanoarrow_schema.");
  }
  const struct ArrowSchema* schema_ptr = nanoarrow_schema_from_xptr(schema);
  std::vector<int> pos(positions.begin(), positions.end());
  res->set_arrow_schema(schema_ptr, pos);
}

// A lazy nanoarrow_array_stream over the remaining rows of the result
[[cpp11::register]]
SEXP result_fetch_arrow(
  cpp11::external_pointer<DbResultPtr> res_,
  double chunk_size
) {
  DbResultPtr* res = res_.get();
  if (res == NULL || res->get() == NULL) {
    cpp11::stop("Invalid result set");
  }
  if (!(*res)->ready()) {
    cpp11::stop("Query needs to be bound before fetching");
  }

  cpp11::sexp stream_xptr(nanoarrow_array_stream_owning_xptr());
  struct ArrowArrayStream* stream =
    nanoarrow_output_array_stream_from_xptr(stream_xptr);
  db_arrow_stream_init(stream, *res, static_cast<int64_t>(chunk_size));
  return stream_xptr;
}

// All remaining rows, fetched up front as arrays of at most `chunk_size` rows:
// a nanoarrow_array_stream that hands them out one by one, and the row count
[[cpp11::register]]
cpp11::list result_fetch_arrow_all(
  cpp11::external_pointer<DbResultPtr> res_,
  double chunk_size
) {
  DbResultPtr* res = res_.get();
  if (res == NULL || res->get() == NULL) {
    cpp11::stop("Invalid result set");
  }
  if (!(*res)->ready()) {
    cpp11::stop("Query needs to be bound before fetching");
  }

  cpp11::sexp stream_xptr(nanoarrow_array_stream_owning_xptr());
  struct ArrowArrayStream* stream =
    nanoarrow_output_array_stream_from_xptr(stream_xptr);
  int64_t n = db_arrow_buffered_stream_init(
    stream,
    *res,
    static_cast<int64_t>(chunk_size)
  );

  using namespace cpp11::literals;
  return cpp11::writable::list(
    { "stream"_nm = stream_xptr,
      "n"_nm = cpp11::as_sexp(static_cast<double>(n)) }
  );
}

// All remaining rows, fetched up front as chunks of at most `chunk_size` rows
// and split by column: one nanoarrow_array_stream per column, the column
// names, and the row count
[[cpp11::register]]
cpp11::list result_fetch_arrow_columns(
  cpp11::external_pointer<DbResultPtr> res_,
  double chunk_size
) {
  DbResultPtr* res = res_.get();
  if (res == NULL || res->get() == NULL) {
    cpp11::stop("Invalid result set");
  }
  if (!(*res)->ready()) {
    cpp11::stop("Query needs to be bound before fetching");
  }

  nanoarrow::UniqueSchema schema;
  (*res)->arrow_schema(schema.get(), static_cast<int64_t>(chunk_size));
  const R_xlen_t ncols = static_cast<R_xlen_t>(schema->n_children);

  cpp11::writable::list columns(ncols);
  cpp11::writable::strings names(ncols);
  std::vector<struct ArrowArrayStream*> outs(static_cast<size_t>(ncols));
  for (R_xlen_t j = 0; j < ncols; ++j) {
    cpp11::sexp stream_xptr(nanoarrow_array_stream_owning_xptr());
    outs[static_cast<size_t>(j)] =
      nanoarrow_output_array_stream_from_xptr(stream_xptr);
    columns[j] = stream_xptr;
    const char* name = schema->children[j]->name;
    names[j] = name == NULL ? "" : name;
  }

  int64_t n = db_arrow_column_streams_init(
    outs,
    *res,
    schema.get(),
    static_cast<int64_t>(chunk_size)
  );

  using namespace cpp11::literals;
  return cpp11::writable::list(
    { "n"_nm = cpp11::as_sexp(static_cast<double>(n)),
      "names"_nm = names,
      "columns"_nm = columns }
  );
}

// The next chunk of at most `chunk_size` rows split by column: one
// nanoarrow_array per column, each owning its buffers, the column names,
// the row count, and the bytes each column holds
[[cpp11::register]]
cpp11::list result_fetch_arrow_chunk_columns(DbResult* res, double chunk_size) {
  nanoarrow::UniqueArray chunk;
  res->fetch_arrow(chunk.get(), static_cast<int64_t>(chunk_size));

  nanoarrow::UniqueSchema schema;
  res->arrow_schema(schema.get(), static_cast<int64_t>(chunk_size));
  const R_xlen_t ncols = static_cast<R_xlen_t>(schema->n_children);

  cpp11::writable::list columns(ncols);
  cpp11::writable::strings names(ncols);
  cpp11::writable::doubles bytes(ncols);
  for (R_xlen_t j = 0; j < ncols; ++j) {
    cpp11::sexp array_xptr(nanoarrow_array_owning_xptr());
    struct ArrowArray* array = nanoarrow_output_array_from_xptr(array_xptr);
    ArrowArrayMove(chunk->children[j], array);

    // The schema of a nanoarrow_array lives in the tag of the external pointer
    cpp11::sexp schema_xptr(nanoarrow_schema_owning_xptr());
    check_arrow(
      ArrowSchemaDeepCopy(
        schema->children[j],
        nanoarrow_output_schema_from_xptr(schema_xptr)
      ),
      "Can't copy Arrow schema"
    );
    R_SetExternalPtrTag(array_xptr, schema_xptr);

    columns[j] = array_xptr;
    const char* name = schema->children[j]->name;
    names[j] = name == NULL ? "" : name;
    bytes[j] = static_cast<double>(arrow_array_bytes(array));
  }

  using namespace cpp11::literals;
  return cpp11::writable::list(
    { "n"_nm = cpp11::as_sexp(static_cast<double>(chunk->length)),
      "names"_nm = names,
      "columns"_nm = columns,
      "bytes"_nm = bytes }
  );
}

// One nanoarrow_array with the values of every array of a stream of strings;
// the stream is consumed, and each of its arrays is freed once copied
[[cpp11::register]]
SEXP arrow_concat_strings(cpp11::sexp stream_xptr) {
  if (!Rf_inherits(stream_xptr, "nanoarrow_array_stream")) {
    cpp11::stop("`stream` must be a nanoarrow_array_stream.");
  }
  struct ArrowArrayStream* stream =
    static_cast<struct ArrowArrayStream*>(R_ExternalPtrAddr(stream_xptr));
  if (stream == NULL || stream->release == NULL) {
    cpp11::stop("The nanoarrow_array_stream has already been released.");
  }

  struct ArrowError error;
  ArrowErrorInit(&error);

  nanoarrow::UniqueSchema schema;
  if (ArrowArrayStreamGetSchema(stream, schema.get(), &error) != NANOARROW_OK) {
    cpp11::stop("Can't read the schema of the Arrow stream: %s", error.message);
  }
  struct ArrowSchemaView schema_view;
  check_arrow(
    ArrowSchemaViewInit(&schema_view, schema.get(), &error),
    "Can't read Arrow schema",
    &error
  );
  if (schema_view.type != NANOARROW_TYPE_STRING &&
      schema_view.type != NANOARROW_TYPE_LARGE_STRING) {
    cpp11::stop(
      "Can't concatenate arrays of Arrow type %s",
      ArrowTypeString(schema_view.type)
    );
  }

  cpp11::sexp out_xptr(nanoarrow_array_owning_xptr());
  struct ArrowArray* out = nanoarrow_output_array_from_xptr(out_xptr);
  check_arrow(
    ArrowArrayInitFromType(out, schema_view.type),
    "Can't allocate Arrow array"
  );
  check_arrow(ArrowArrayStartAppending(out), "Can't allocate Arrow array");

  nanoarrow::UniqueArrayView view;
  check_arrow(
    ArrowArrayViewInitFromSchema(view.get(), schema.get(), &error),
    "Can't read Arrow schema",
    &error
  );

  while (true) {
    nanoarrow::UniqueArray array;
    if (ArrowArrayStreamGetNext(stream, array.get(), &error) != NANOARROW_OK) {
      cpp11::stop("Can't read the Arrow stream: %s", error.message);
    }
    if (array->release == NULL) {
      break;
    }
    check_arrow(
      ArrowArrayViewSetArray(view.get(), array.get(), &error),
      "Can't read Arrow array",
      &error
    );
    for (int64_t i = 0; i < array->length; ++i) {
      if (ArrowArrayViewIsNull(view.get(), i)) {
        check_arrow(
          ArrowArrayAppendNull(out, 1),
          "Can't append to Arrow array"
        );
      } else {
        check_arrow(
          ArrowArrayAppendString(
            out,
            ArrowArrayViewGetStringUnsafe(view.get(), i)
          ),
          "Can't append to Arrow array"
        );
      }
    }
    cpp11::check_user_interrupt();
  }
  check_arrow(
    ArrowArrayFinishBuildingDefault(out, &error),
    "Can't finish Arrow array",
    &error
  );

  cpp11::sexp schema_xptr(nanoarrow_schema_owning_xptr());
  check_arrow(
    ArrowSchemaDeepCopy(
      schema.get(),
      nanoarrow_output_schema_from_xptr(schema_xptr)
    ),
    "Can't copy Arrow schema"
  );
  R_SetExternalPtrTag(out_xptr, schema_xptr);
  return out_xptr;
}

// The next chunk of at most `chunk_size` rows as a nanoarrow_array,
// with the bytes its buffers hold
[[cpp11::register]]
cpp11::list result_fetch_arrow_chunk(DbResult* res, double chunk_size) {
  cpp11::sexp array_xptr(nanoarrow_array_owning_xptr());
  struct ArrowArray* array = nanoarrow_output_array_from_xptr(array_xptr);
  res->fetch_arrow(array, static_cast<int64_t>(chunk_size));

  // The schema of a nanoarrow_array lives in the tag of the external pointer
  cpp11::sexp schema_xptr(nanoarrow_schema_owning_xptr());
  res->arrow_schema(
    nanoarrow_output_schema_from_xptr(schema_xptr),
    static_cast<int64_t>(chunk_size)
  );
  R_SetExternalPtrTag(array_xptr, schema_xptr);

  using namespace cpp11::literals;
  return cpp11::writable::list(
    { "array"_nm = array_xptr,
      "bytes"_nm =
        cpp11::as_sexp(static_cast<double>(arrow_array_bytes(array))) }
  );
}

// Binds all rows of a nanoarrow_array_stream, `param_indexes` gives the
// zero-based child for each placeholder; the stream is consumed
[[cpp11::register]]
void result_bind_arrow(
  DbResult* res,
  cpp11::sexp params,
  cpp11::integers param_indexes
) {
  if (!Rf_inherits(params, "nanoarrow_array_stream")) {
    cpp11::stop("`params` must be a nanoarrow_array_stream.");
  }
  struct ArrowArrayStream* stream =
    static_cast<struct ArrowArrayStream*>(R_ExternalPtrAddr(params));
  if (stream == NULL || stream->release == NULL) {
    cpp11::stop("The nanoarrow_array_stream has already been released.");
  }

  std::vector<int> indexes(param_indexes.begin(), param_indexes.end());
  res->bind_arrow(stream, indexes);
}

// The values of an integer64 vector as an integer vector,
// or NULL if one of them does not fit
[[cpp11::register]]
SEXP integer64_to_integer(cpp11::doubles x) {
  const R_xlen_t n = x.size();
  const int64_t* values = reinterpret_cast<const int64_t*>(REAL(x));
  for (R_xlen_t i = 0; i < n; ++i) {
    const int64_t value = values[i];
    if (value != NA_INTEGER64 && (value < -INT_MAX || value > INT_MAX)) {
      return R_NilValue;
    }
  }

  cpp11::writable::integers out(n);
  for (R_xlen_t i = 0; i < n; ++i) {
    const int64_t value = values[i];
    out[i] = (value == NA_INTEGER64) ? NA_INTEGER : static_cast<int>(value);
  }
  return out;
}
