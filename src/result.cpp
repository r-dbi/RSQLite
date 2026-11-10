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
  DbResultPtr* ptr = res.get();
  if (ptr != NULL && ptr->get() != NULL && (*ptr)->busy()) {
    // Freeing it would pull the statement from under the running fetch
    cpp11::stop(
      "Can't clear a result while one of its fetches or binds is running, "
      "as from a handler of a warning that it raised."
    );
  }
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

// An integer while it fits, a double beyond INT_MAX, where R integers end
[[cpp11::register]]
SEXP result_rows_fetched(DbResult* res) {
  int64_t n = res->n_rows_fetched();
  if (n <= INT_MAX) {
    return cpp11::as_sexp(static_cast<int>(n));
  }
  return cpp11::as_sexp(static_cast<double>(n));
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
// at the zero-based `positions`, before the first row is fetched; `seconds`
// marks the times and timestamps that a data frame fetch stores as doubles in
// seconds, like decided ones
[[cpp11::register]]
void result_set_arrow_schema(
  DbResult* res,
  cpp11::sexp schema,
  cpp11::integers positions,
  cpp11::logicals seconds
) {
  if (!Rf_inherits(schema, "nanoarrow_schema")) {
    cpp11::stop("`schema` must be a nanoarrow_schema.");
  }
  const struct ArrowSchema* schema_ptr = nanoarrow_schema_from_xptr(schema);
  std::vector<int> pos(positions.begin(), positions.end());
  std::vector<bool> secs;
  for (R_xlen_t i = 0; i < seconds.size(); ++i) {
    secs.push_back(seconds[i] == TRUE);
  }
  res->set_arrow_schema(schema_ptr, pos, secs);
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

// The rows of one dbFetch() through Arrow, at most `n_max` or all for a
// negative `n_max`, typed for a data frame and fetched up front as arrays of at
// most `chunk_size` rows: a list of nanoarrow_array objects with their
// lengths, the row count, the names and Arrow formats of the columns, which
// columns have seen an integer that needs 64 bits, the R class of the
// columns of times or timestamps in seconds, and the entries of the warning
// for the values that were not of their column's type, or NULL.
// Everything the conversion needs comes from here, which spares a small fetch
// the R proxies of the Arrow objects.
[[cpp11::register]]
cpp11::list result_fetch_arrow_df(
  DbResult* res,
  double n_max,
  double chunk_size
) {
  nanoarrow::UniqueArrayStream stream;
  ArrowDfColumns columns;
  int64_t n = res->fetch_arrow_df(
    stream.get(),
    columns,
    static_cast<int64_t>(n_max),
    static_cast<int64_t>(chunk_size)
  );

  cpp11::sexp schema_xptr(nanoarrow_schema_owning_xptr());
  struct ArrowSchema* schema = nanoarrow_output_schema_from_xptr(schema_xptr);
  check_arrow(
    stream->get_schema(stream.get(), schema),
    "Can't get Arrow schema"
  );

  const R_xlen_t ncols = static_cast<R_xlen_t>(schema->n_children);
  cpp11::writable::strings names(ncols);
  cpp11::writable::strings formats(ncols);
  cpp11::writable::logicals wide(ncols);
  cpp11::writable::strings seconds(ncols);
  for (R_xlen_t j = 0; j < ncols; ++j) {
    names[j] = cpp11::r_string(schema->children[j]->name);
    formats[j] = schema->children[j]->format;
    wide[j] = static_cast<bool>(columns.wide_ints[j]);
    seconds[j] = columns.seconds_classes[j];
  }

  cpp11::writable::list arrays;
  cpp11::writable::doubles lengths;
  while (true) {
    cpp11::sexp array_xptr(nanoarrow_array_owning_xptr());
    struct ArrowArray* array = nanoarrow_output_array_from_xptr(array_xptr);
    check_arrow(stream->get_next(stream.get(), array), "Can't get Arrow array");
    if (array->release == NULL) {
      break;
    }
    R_SetExternalPtrTag(array_xptr, schema_xptr);
    arrays.push_back(array_xptr);
    lengths.push_back(static_cast<double>(array->length));
  }

  using namespace cpp11::literals;
  return cpp11::writable::list(
    { "arrays"_nm = arrays,
      "lengths"_nm = lengths,
      "n"_nm = cpp11::as_sexp(static_cast<double>(n)),
      "names"_nm = names,
      "formats"_nm = formats,
      "wide_ints"_nm = wide,
      "seconds"_nm = seconds,
      "coercions"_nm = columns.coercions }
  );
}

// The columns of struct arrays that share their schema, such as those of
// result_fetch_arrow_df(), as one nanoarrow_array_stream per column, so that
// each column can be converted on its own and its arrays released with it,
// with the bytes that the arrays of each column hold.
// The children move out of the arrays, which are released with what is left.
[[cpp11::register]]
cpp11::list arrow_split_columns(cpp11::list arrays) {
  const R_xlen_t n_arrays = arrays.size();
  if (n_arrays == 0) {
    cpp11::stop("Internal error: no arrays to split");
  }
  for (R_xlen_t i = 0; i < n_arrays; ++i) {
    SEXP array_xptr = arrays[i];
    if (!Rf_inherits(array_xptr, "nanoarrow_array")) {
      cpp11::stop("`arrays` must be a list of nanoarrow_array objects.");
    }
    struct ArrowArray* array =
      static_cast<struct ArrowArray*>(R_ExternalPtrAddr(array_xptr));
    if (array == NULL || array->release == NULL) {
      cpp11::stop("A nanoarrow_array has already been released.");
    }
  }
  SEXP schema_xptr = R_ExternalPtrTag(arrays[0]);
  if (!Rf_inherits(schema_xptr, "nanoarrow_schema")) {
    cpp11::stop("The nanoarrow_array has no schema.");
  }
  const struct ArrowSchema* schema =
    static_cast<struct ArrowSchema*>(R_ExternalPtrAddr(schema_xptr));
  const R_xlen_t ncols = static_cast<R_xlen_t>(schema->n_children);
  const size_t ncols_ = static_cast<size_t>(ncols);

  // The R objects first, an allocation error leaves no C++ object behind
  cpp11::writable::list columns(ncols);
  for (R_xlen_t j = 0; j < ncols; ++j) {
    columns[j] = nanoarrow_array_stream_owning_xptr();
  }

  std::vector<nanoarrow::UniqueSchema> schemas(ncols_);
  for (size_t j = 0; j < ncols_; ++j) {
    check_arrow(
      ArrowSchemaDeepCopy(schema->children[j], schemas[j].get()),
      "Can't copy Arrow schema"
    );
  }

  cpp11::writable::doubles bytes(ncols);
  for (R_xlen_t j = 0; j < ncols; ++j) {
    bytes[j] = 0;
  }

  std::vector<std::vector<nanoarrow::UniqueArray> > split(ncols_);
  for (R_xlen_t i = 0; i < n_arrays; ++i) {
    struct ArrowArray* array =
      static_cast<struct ArrowArray*>(R_ExternalPtrAddr(arrays[i]));
    if (array->n_children != schema->n_children) {
      cpp11::stop("Internal error: column count mismatch");
    }
    nanoarrow::UniqueArray chunk;
    ArrowArrayMove(array, chunk.get());
    // The struct releases only the children that are left
    for (size_t j = 0; j < ncols_; ++j) {
      nanoarrow::UniqueArray column;
      ArrowArrayMove(chunk->children[j], column.get());
      bytes[static_cast<R_xlen_t>(j)] +=
        static_cast<double>(arrow_array_bytes(column.get()));
      split[j].push_back(std::move(column));
    }
  }

  for (R_xlen_t j = 0; j < ncols; ++j) {
    db_arrow_buffered_stream_init(
      nanoarrow_output_array_stream_from_xptr(columns[j]),
      schemas[static_cast<size_t>(j)],
      split[static_cast<size_t>(j)]
    );
  }

  using namespace cpp11::literals;
  return cpp11::writable::list({ "streams"_nm = columns, "bytes"_nm = bytes });
}

namespace {

// The bytes of string data above which concatenated strings take the
// large_utf8 type: the 32-bit offsets of utf8 address at most this many
int64_t concat_utf8_max_bytes = INT32_MAX;

// The bytes of string data that an array view holds
int64_t string_data_bytes(const struct ArrowArrayView* view) {
  if (view->length == 0) {
    return 0;
  }
  const int64_t first = view->offset;
  const int64_t last = view->offset + view->length;
  if (view->storage_type == NANOARROW_TYPE_LARGE_STRING) {
    const int64_t* offsets = view->buffer_views[1].data.as_int64;
    return offsets[last] - offsets[first];
  }
  const int32_t* offsets = view->buffer_views[1].data.as_int32;
  return static_cast<int64_t>(offsets[last]) - offsets[first];
}

// The bytes that the buffers of an array view span
int64_t view_bytes(const struct ArrowArrayView* view) {
  int64_t bytes = 0;
  for (int i = 0; i < NANOARROW_MAX_FIXED_BUFFERS; ++i) {
    bytes += view->buffer_views[i].size_bytes;
  }
  return bytes;
}

}  // namespace

// One nanoarrow_array with the values of every array of a stream of strings,
// with the bytes its buffers hold; the stream is consumed.
// A single array is handed on as it is. Several arrays are copied into a new
// one, each freed once copied, which takes the large_utf8 type when their
// strings need more bytes than the 32-bit offsets of utf8 can address.
[[cpp11::register]]
cpp11::list arrow_concat_strings(cpp11::sexp stream_xptr) {
  if (!Rf_inherits(stream_xptr, "nanoarrow_array_stream")) {
    cpp11::stop("`stream` must be a nanoarrow_array_stream.");
  }
  struct ArrowArrayStream* stream =
    static_cast<struct ArrowArrayStream*>(R_ExternalPtrAddr(stream_xptr));
  if (stream == NULL || stream->release == NULL) {
    cpp11::stop("The nanoarrow_array_stream has already been released.");
  }

  cpp11::sexp out_xptr(nanoarrow_array_owning_xptr());
  cpp11::sexp schema_xptr(nanoarrow_schema_owning_xptr());
  struct ArrowArray* out = nanoarrow_output_array_from_xptr(out_xptr);
  struct ArrowSchema* out_schema =
    nanoarrow_output_schema_from_xptr(schema_xptr);

  struct ArrowError error;
  ArrowErrorInit(&error);

  nanoarrow::UniqueSchema schema;
  if (ArrowArrayStreamGetSchema(stream, schema.get(), &error) != NANOARROW_OK) {
    cpp11::stop(
      "Can't read the schema of the Arrow stream: %s",
      ArrowArrayStreamGetLastError(stream)
    );
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

  // All arrays first, so that the sizes are known before the copy
  std::vector<nanoarrow::UniqueArray> arrays;
  while (true) {
    nanoarrow::UniqueArray array;
    if (ArrowArrayStreamGetNext(stream, array.get(), &error) != NANOARROW_OK) {
      cpp11::stop(
        "Can't read the Arrow stream: %s",
        ArrowArrayStreamGetLastError(stream)
      );
    }
    if (array->release == NULL) {
      break;
    }
    arrays.push_back(std::move(array));
  }
  ArrowArrayStreamRelease(stream);

  nanoarrow::UniqueArrayView view;
  check_arrow(
    ArrowArrayViewInitFromSchema(view.get(), schema.get(), &error),
    "Can't read Arrow schema",
    &error
  );
  int64_t length = 0;
  int64_t data_bytes = 0;
  for (size_t i = 0; i < arrays.size(); ++i) {
    check_arrow(
      ArrowArrayViewSetArray(view.get(), arrays[i].get(), &error),
      "Can't read Arrow array",
      &error
    );
    length += arrays[i]->length;
    data_bytes += string_data_bytes(view.get());
  }

  check_arrow(
    ArrowSchemaDeepCopy(schema.get(), out_schema),
    "Can't copy Arrow schema"
  );
  R_SetExternalPtrTag(out_xptr, schema_xptr);

  using namespace cpp11::literals;
  if (arrays.size() == 1) {
    ArrowArrayMove(arrays[0].get(), out);
    check_arrow(
      ArrowArrayViewSetArray(view.get(), out, &error),
      "Can't read Arrow array",
      &error
    );
    return cpp11::writable::list(
      { "array"_nm = out_xptr,
        "bytes"_nm =
          cpp11::as_sexp(static_cast<double>(view_bytes(view.get()))) }
    );
  }

  enum ArrowType type = schema_view.type;
  if (data_bytes > concat_utf8_max_bytes) {
    type = NANOARROW_TYPE_LARGE_STRING;
  }
  if (type != schema_view.type) {
    check_arrow(
      ArrowSchemaSetFormat(out_schema, "U"),
      "Can't set the Arrow format"
    );
  }

  check_arrow(ArrowArrayInitFromType(out, type), "Can't allocate Arrow array");
  check_arrow(ArrowArrayStartAppending(out), "Can't allocate Arrow array");
  check_arrow(ArrowArrayReserve(out, length), "Can't allocate Arrow array");
  check_arrow(
    ArrowBufferReserve(ArrowArrayBuffer(out, 2), data_bytes),
    "Can't allocate Arrow array"
  );

  for (size_t i = 0; i < arrays.size(); ++i) {
    check_arrow(
      ArrowArrayViewSetArray(view.get(), arrays[i].get(), &error),
      "Can't read Arrow array",
      &error
    );
    for (int64_t j = 0; j < arrays[i]->length; ++j) {
      if (ArrowArrayViewIsNull(view.get(), j)) {
        check_arrow(
          ArrowArrayAppendNull(out, 1),
          "Can't append to Arrow array"
        );
      } else {
        check_arrow(
          ArrowArrayAppendString(
            out,
            ArrowArrayViewGetStringUnsafe(view.get(), j)
          ),
          "Can't append to Arrow array"
        );
      }
    }
    arrays[i].reset();
    cpp11::check_user_interrupt();
  }
  check_arrow(
    ArrowArrayFinishBuildingDefault(out, &error),
    "Can't finish Arrow array",
    &error
  );

  return cpp11::writable::list(
    { "array"_nm = out_xptr,
      "bytes"_nm = cpp11::as_sexp(static_cast<double>(arrow_array_bytes(out))) }
  );
}

// For the tests: sets the bytes of string data above which concatenated
// strings take the large_utf8 type, and returns the previous value
[[cpp11::register]]
double arrow_set_concat_utf8_max_bytes(double max_bytes) {
  const int64_t old = concat_utf8_max_bytes;
  concat_utf8_max_bytes = static_cast<int64_t>(max_bytes);
  return static_cast<double>(old);
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

// For the tests: sets, for this result alone, the bytes of a utf8 or binary
// column after which, or beyond which, an Arrow chunk ends
[[cpp11::register]]
void result_set_bytes_limits(
  SqliteResult* res,
  double cut_bytes,
  double max_bytes
) {
  res->set_arrow_bytes_limits(
    static_cast<int64_t>(cut_bytes),
    static_cast<int64_t>(max_bytes)
  );
}

// For the tests: how often an R condition raised while RSQLite's own C++ code
// read an Arrow stream of this result has been rethrown as a C++ exception
[[cpp11::register]]
double result_rethrown_unwinds(DbResult* res) {
  return static_cast<double>(res->rethrown_unwinds());
}

// For the tests: sets the number of rows fetched from the statement
[[cpp11::register]]
void result_set_rows_fetched(SqliteResult* res, double n) {
  res->set_rows_fetched(static_cast<int64_t>(n));
}
