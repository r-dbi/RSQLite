#include "pch.h"
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
cpp11::strings result_get_placeholder_names(SqliteResult* res) {
  return res->get_placeholder_names();
}

// Arrow ///////////////////////////////////////////////////////////////////////

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
// columns have seen an integer that needs 64 bits, and the R class of the
// columns of times or timestamps in seconds.
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
      "seconds"_nm = seconds }
  );
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
