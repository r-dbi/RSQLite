#include "pch.h"
#include "DbArrow.h"
#include "DbArrowStream.h"

namespace {

struct StreamState {
  DbResultPtr result;
  int64_t chunk_size;
  // The execution of the statement whose rows the stream reads
  int64_t executions;
  // Set when C++ code of this package reads the stream, see below
  bool rethrow_unwind;
  nanoarrow::UniqueSchema schema;
  std::string last_error;

  StreamState(const DbResultPtr& result_, int64_t chunk_size_)
      : result(result_),
        chunk_size(chunk_size_),
        executions(result_->executions()),
        rethrow_unwind(false) {}
};

StreamState* get_state(struct ArrowArrayStream* stream) {
  return static_cast<StreamState*>(stream->private_data);
}

// New parameters execute the statement again, with new rows and possibly
// other types than those of the schema handed out
void check_executions(StreamState* state) {
  if (state->result->executions() != state->executions) {
    throw std::runtime_error(
      "The result was bound to new parameters after the Arrow stream was "
      "created, call dbFetchArrow() again"
    );
  }
}

void ensure_schema(StreamState* state) {
  if (state->schema->release != NULL) {
    return;
  }
  if (!state->result) {
    throw std::runtime_error("The Arrow stream has already been consumed");
  }
  check_executions(state);
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
  check_executions(state);

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
// When C++ code of this package is the consumer, the exception is rethrown
// instead, so that the unwind is continued at the entry point after the
// consumer's C++ objects have been destroyed.
// A C++ consumer of another package, such as arrow, still sees the longjmp:
// the C stream interface has no other way to carry an R condition.
// The conditions are interrupts, and warnings that a handler or
// `options(warn = 2)` turns into a jump.

int stream_get_schema(
  struct ArrowArrayStream* stream,
  struct ArrowSchema* out
) {
  StreamState* state = get_state(stream);
  SEXP token = R_NilValue;
  try {
    return get_schema_impl(state, out);
  } catch (const cpp11::unwind_exception& e) {
    if (state->rethrow_unwind) {
      throw;
    }
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
    if (state->rethrow_unwind) {
      throw;
    }
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

void db_arrow_stream_read_from_cpp(struct ArrowArrayStream* stream) {
  if (stream->release == &stream_release) {
    get_state(stream)->rethrow_unwind = true;
  }
}
