#include "pch.h"
#include "DbArrow.h"
#include "DbArrowStream.h"

namespace {

struct StreamState {
  DbResultPtr result;
  int64_t chunk_size;
  nanoarrow::UniqueSchema schema;
  std::string last_error;

  StreamState(const DbResultPtr& result_, int64_t chunk_size_)
      : result(result_), chunk_size(chunk_size_) {}
};

StreamState* get_state(struct ArrowArrayStream* stream) {
  return static_cast<StreamState*>(stream->private_data);
}

void ensure_schema(StreamState* state) {
  if (state->schema->release != NULL) {
    return;
  }
  if (!state->result) {
    throw std::runtime_error("The Arrow stream has already been consumed");
  }
  state->result->arrow_schema(state->schema.get(), state->chunk_size);
}

int get_schema_impl(StreamState* state, struct ArrowSchema* out) {
  ensure_schema(state);
  check_arrow(
    ArrowSchemaDeepCopy(state->schema.get(), out),
    "Can't copy Arrow schema"
  );
  return NANOARROW_OK;
}

int get_next_impl(StreamState* state, struct ArrowArray* out) {
  if (!state->result) {
    // End of stream
    out->release = NULL;
    return NANOARROW_OK;
  }

  ensure_schema(state);

  nanoarrow::UniqueArray array;
  int64_t n = state->result->fetch_arrow(array.get(), state->chunk_size);
  if (n == 0 && state->result->complete()) {
    // Release the result as early as possible
    state->result.reset();
    out->release = NULL;
    return NANOARROW_OK;
  }

  ArrowArrayMove(array.get(), out);
  return NANOARROW_OK;
}

// The callbacks below run inside the C code of the stream consumer.
// C++ exceptions are turned into stream errors.
// An R error or interrupt raised through cpp11 arrives as a
// cpp11::unwind_exception; its unwind is continued after leaving the try block
// with no C++ objects alive, exactly like cpp11's entry-point wrapper does.

int stream_get_schema(
  struct ArrowArrayStream* stream,
  struct ArrowSchema* out
) {
  StreamState* state = get_state(stream);
  SEXP token = R_NilValue;
  try {
    return get_schema_impl(state, out);
  } catch (const cpp11::unwind_exception& e) {
    token = e.token;
  } catch (const std::exception& e) {
    state->last_error = e.what();
    return EIO;
  } catch (...) {
    state->last_error = "Unknown C++ error";
    return EIO;
  }
  R_ContinueUnwind(token);
  return EIO;
}

int stream_get_next(struct ArrowArrayStream* stream, struct ArrowArray* out) {
  StreamState* state = get_state(stream);
  SEXP token = R_NilValue;
  try {
    return get_next_impl(state, out);
  } catch (const cpp11::unwind_exception& e) {
    token = e.token;
  } catch (const std::exception& e) {
    state->last_error = e.what();
    return EIO;
  } catch (...) {
    state->last_error = "Unknown C++ error";
    return EIO;
  }
  R_ContinueUnwind(token);
  return EIO;
}

const char* stream_get_last_error(struct ArrowArrayStream* stream) {
  return get_state(stream)->last_error.c_str();
}

void stream_release(struct ArrowArrayStream* stream) {
  delete get_state(stream);
  stream->private_data = NULL;
  stream->release = NULL;
}

}  // namespace

void db_arrow_stream_init(
  struct ArrowArrayStream* out,
  const DbResultPtr& result,
  int64_t chunk_size
) {
  out->get_schema = &stream_get_schema;
  out->get_next = &stream_get_next;
  out->get_last_error = &stream_get_last_error;
  out->release = &stream_release;
  out->private_data = new StreamState(result, chunk_size);
}
