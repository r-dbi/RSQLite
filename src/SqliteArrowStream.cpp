#include "pch.h"
#include "RSQLite_types.h"
#include "DbArrow.h"
// After DbArrow.h, so that the Arrow C structs are defined once
#include <nanoarrow/r.h>
#include <cerrno>
#include <type_traits>

// An Arrow array stream over an open result:
// each get_next() fetches the next chunk of the result,
// as result_fetch_arrow_chunk() does.
//
// The stream shares the result with its R object,
// so that the result and its statement live as long as the stream reads them:
// it reads on after dbClearResult(), dbDisconnect(),
// or R's garbage collector have dropped the R objects
// of the result and its connection.
// The statement is finalized, and a disconnected connection closed,
// once the last stream that reads them has ended or is released.
// Once the result is bound to new parameters,
// the next get_schema() or get_next() fails with an error that says so.
// The callbacks run on R's main thread, inside the consumer's C code,
// such as nanoarrow's conversion.

namespace {

struct StreamState {
  // Dropped once the stream has ended, see drop_result()
  DbResultPtr result;
  // The execution whose rows the stream reads
  const int executions;
  const int n_max;
  nanoarrow::UniqueSchema schema;
  bool done;
  // Set once a fetch has failed, see run_callback()
  bool failed;
  std::string last_error;
  // The callbacks running, and whether release() came meanwhile,
  // as from a handler of a warning that the fetch raised:
  // the state is deleted once the last of them returns
  int running;
  bool released;

  StreamState(const DbResultPtr& result_, int n_max_)
      : result(result_),
        executions(result_->executions()),
        n_max(n_max_),
        done(false),
        failed(false),
        running(0),
        released(false) {
    result->add_stream();
  }

  ~StreamState() {
    drop_result();
  }

  // Finalizes the statement unless R or another stream still holds the result,
  // and closes a disconnected connection unless another stream reads from it:
  // sqlite3_close_v2() completes once the statements are finalized
  void drop_result() {
    if (result) {
      result->remove_stream();
      result.reset();
    }
  }
};

StreamState* get_state(struct ArrowArrayStream* stream) {
  return static_cast<StreamState*>(stream->private_data);
}

// The result, while the stream can read it
DbResult* checked_result(StreamState* state) {
  DbResult* result = state->result.get();
  if (result->executions() != state->executions) {
    throw std::runtime_error(
      "Can't read an Arrow stream after its result has been bound "
      "to new parameters."
    );
  }
  return result;
}

// The schema is read once, before the first chunk, and kept:
// it stays readable once the stream has ended
void ensure_schema(StreamState* state, DbResult* result) {
  if (state->schema->release == NULL) {
    result->arrow_schema(state->schema.get(), state->n_max);
  }
}

void get_schema_impl(StreamState* state, struct ArrowSchema* out) {
  if (state->failed && state->schema->release == NULL) {
    throw std::runtime_error(state->last_error);
  }
  if (state->schema->release == NULL) {
    ensure_schema(state, checked_result(state));
  }
  check_arrow(
    ArrowSchemaDeepCopy(state->schema.get(), out),
    "Can't copy Arrow schema"
  );
}

void get_next_impl(StreamState* state, struct ArrowArray* out) {
  out->release = NULL;
  if (state->failed) {
    throw std::runtime_error(state->last_error);
  }
  if (state->done) {
    return;
  }
  DbResult* result = checked_result(state);
  ensure_schema(state, result);
  nanoarrow::UniqueArray array;
  if (!result->complete()) {
    nanoarrow::UniqueSchema schema;
    result->fetch_arrow_chunk(array.get(), schema.get(), state->n_max);
  }
  // A result without rows ends the stream with no chunk:
  // only the chunk that get_schema() keeps for it can be empty
  if (array->release == NULL || (array->length == 0 && result->complete())) {
    state->done = true;
    state->drop_result();
    return;
  }
  ArrowArrayMove(array.get(), out);
}

// A callback of the stream, see run_callback()
struct Callback {
  StreamState* state;
  void (*run)(void*);
  void* body;
  int code;
  bool returned;
  SEXP token;
};

SEXP callback_body(void* data) {
  Callback* call = static_cast<Callback*>(data);
  StreamState* state = call->state;
  try {
    call->run(call->body);
    call->code = NANOARROW_OK;
  } catch (const cpp11::unwind_exception& e) {
    call->token = e.token;
    state->last_error =
      "Can't read an Arrow stream after an R condition interrupted a fetch.";
  } catch (const std::exception& e) {
    state->last_error = e.what();
  } catch (...) {
    state->last_error = "Unknown C++ error";
  }
  call->returned = true;
  return R_NilValue;
}

// Runs when the body returns,
// and also when an R error leaves it by a jump that bypasses cpp11,
// such as a failed allocation in R's API
void callback_cleanup(void* data) {
  Callback* call = static_cast<Callback*>(data);
  StreamState* state = call->state;
  if (!call->returned) {
    state->last_error =
      "Can't read an Arrow stream after an R error interrupted a fetch.";
  }
  --state->running;
  // A call from a handler during another callback, which the busy guard
  // refuses, leaves the stream to that callback.
  // The flag is never cleared once set.
  if (call->code != NANOARROW_OK && state->running == 0 && !state->failed) {
    const DbResult* result = state->result.get();
    state->failed = result == NULL || !result->arrow_chunk_kept();
  }
  if (state->released && state->running == 0) {
    delete state;
  }
}

// Runs `body` for a callback: an error becomes the error of the stream.
// An R condition that leaves the fetch by a jump, such as an interrupt,
// or a warning that a handler or options(warn = 2) turns into an error,
// arrives as a cpp11::unwind_exception.
// Its jump goes on once the C++ objects of the callback are destroyed,
// as at cpp11's entry points, through the C code of the consumer.
// R_ExecWithCleanup() keeps the count of running callbacks right,
// also for a jump that bypasses cpp11, as run_guarded() in DbResult.cpp
// does for the busy flag; such a jump still skips the C++ destructors
// of the body.
//
// A failure is final: later calls fail with its message,
// rather than end the stream as if the rows were complete,
// as the result is after a failed fetch.
// Only a chunk kept when its warning exited comes with the next call.
template <typename F>
int run_callback(StreamState* state, F&& body) {
  typedef typename std::remove_reference<F>::type Body;
  Callback call = { state, [](void* f) { (*static_cast<Body*>(f))(); },
                    &body, EIO,
                    false, R_NilValue };
  ++state->running;
  R_ExecWithCleanup(callback_body, &call, callback_cleanup, &call);
  // The state may be gone now, see stream_release()
  if (call.token != R_NilValue) {
    R_ContinueUnwind(call.token);
  }
  return call.code;
}

// A stream released during one of its callbacks,
// as from a handler of a warning that the callback raised,
// can still be called by a consumer that doesn't check its release
const char* released_error = "The Arrow stream has been released.";

int stream_get_schema(
  struct ArrowArrayStream* stream,
  struct ArrowSchema* out
) {
  StreamState* state = get_state(stream);
  if (state == NULL) {
    return EINVAL;
  }
  return run_callback(state, [&] { get_schema_impl(state, out); });
}

int stream_get_next(struct ArrowArrayStream* stream, struct ArrowArray* out) {
  StreamState* state = get_state(stream);
  if (state == NULL) {
    out->release = NULL;
    return EINVAL;
  }
  return run_callback(state, [&] { get_next_impl(state, out); });
}

const char* stream_get_last_error(struct ArrowArrayStream* stream) {
  StreamState* state = get_state(stream);
  if (state == NULL) {
    return released_error;
  }
  return state->last_error.c_str();
}

// Destroys the result if R has dropped it,
// as R's garbage collector does when it frees the stream.
// During a callback, the callback deletes the state once it returns:
// it goes on with the state and the result.
void stream_release(struct ArrowArrayStream* stream) {
  StreamState* state = get_state(stream);
  if (state->running > 0) {
    state->released = true;
  } else {
    delete state;
  }
  stream->private_data = NULL;
  stream->release = NULL;
}

}  // namespace

// The rows of `res` as a nanoarrow_array_stream,
// fetched lazily in chunks of at most `n` rows, all of them for -1.
// Internal for now: no DBI method calls it yet, see read_arrow_stream().
[[cpp11::register]]
SEXP result_create_arrow_stream(
  cpp11::external_pointer<DbResultPtr> res,
  const int n
) {
  DbResultPtr* result = res.get();
  if (result == NULL || result->get() == NULL) {
    cpp11::stop("Invalid result set");
  }
  if (n == 0 || n < -1) {
    cpp11::stop("`n` must be positive, or -1 for all rows.");
  }
  // The stream keeps a connection open, not one closed already
  if (!(*result)->connection_valid()) {
    cpp11::stop(
      "Can't read a result as an Arrow stream after its connection "
      "has been closed."
    );
  }
  cpp11::sexp stream_xptr(cpp11::safe[nanoarrow_array_stream_owning_xptr]());
  struct ArrowArrayStream* stream =
    nanoarrow_output_array_stream_from_xptr(stream_xptr);
  stream->private_data = new StreamState(*result, n);
  stream->get_schema = &stream_get_schema;
  stream->get_next = &stream_get_next;
  stream->get_last_error = &stream_get_last_error;
  stream->release = &stream_release;
  return stream_xptr;
}
