#include "pch.h"
#include "DbArrow.h"
#include "DbArrowStream.h"
#include "main_thread.h"

#include <mutex>
#include <thread>
#include <vector>

// R's main thread /////////////////////////////////////////////////////////////

namespace {

std::thread::id main_thread;

}  // namespace

// Records R's main thread, R_init_RSQLite() runs on it
[[cpp11::init]]
void rsqlite_init_main_thread(DllInfo* dll) {
  (void)dll;
  main_thread = std::this_thread::get_id();
}

bool rsqlite_on_main_thread() {
  return std::this_thread::get_id() == main_thread;
}

void rsqlite_warning(const std::string& message) {
  if (rsqlite_on_main_thread()) {
    cpp11::warning(message);
    return;
  }
  throw std::runtime_error(
    message +
    " (an error instead of a warning, because R can't warn on the thread that "
    "reads the Arrow stream)"
  );
}

// Results released off R's main thread ////////////////////////////////////////

namespace {

// A share of a result dropped by a stream on another thread waits here for
// R's main thread: the result can hold R objects, such as its parameters,
// that only R's main thread may release. Dropping the share right away could
// destroy the result there, should R's main thread drop the other share at the
// same time.
std::mutex deferred_mutex;
std::vector<DbResultPtr> deferred_results;

// Drops the stream's share of its result, on any thread
void drop_result(DbResultPtr& result) {
  if (!result || rsqlite_on_main_thread()) {
    result.reset();
    return;
  }
  if (result.use_count() == 1) {
    // No other share can appear: closes the statement and its read
    // transaction right away, without R
    result->finalize_statement();
  }
  std::lock_guard<std::mutex> lock(deferred_mutex);
  deferred_results.push_back(result);
  result.reset();
}

}  // namespace

void db_arrow_release_deferred() {
  std::vector<DbResultPtr> results;
  {
    std::lock_guard<std::mutex> lock(deferred_mutex);
    results.swap(deferred_results);
  }
  // Destroyed here, on R's main thread
}

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

void ensure_schema(StreamState* state) {
  if (state->schema->release != NULL) {
    return;
  }
  if (!state->result) {
    throw std::runtime_error("The Arrow stream has already been consumed");
  }
  state->result
    ->arrow_schema(state->schema.get(), state->chunk_size, state->executions);
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
  bool complete = false;
  int64_t n = state->result->fetch_arrow(
    array.get(),
    state->chunk_size,
    state->executions,
    &complete
  );
  if (n == 0 && complete) {
    // Release the result as early as possible
    drop_result(state->result);
    out->release = NULL;
    return NANOARROW_OK;
  }

  ArrowArrayMove(array.get(), out);
  return NANOARROW_OK;
}

// The callbacks below run inside the C code of the stream consumer, on R's
// main thread or, for consumers such as arrow's scanner and Acero, on a worker
// thread, also while R goes on: there, no R API is called at all, what would
// be an R warning or error becomes the error of the stream, and the result is
// used only inside its busy mark, see run_guarded() in DbResult.cpp.
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
    if (rsqlite_on_main_thread()) {
      db_arrow_release_deferred();
    }
    return get_schema_impl(state, out);
  } catch (const cpp11::unwind_exception& e) {
    if (state->rethrow_unwind) {
      if (state->result) {
        state->result->count_rethrown_unwind();
      }
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
    if (rsqlite_on_main_thread()) {
      db_arrow_release_deferred();
    }
    return get_next_impl(state, out);
  } catch (const cpp11::unwind_exception& e) {
    if (state->rethrow_unwind) {
      if (state->result) {
        state->result->count_rethrown_unwind();
      }
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
  StreamState* state = get_state(stream);
  drop_result(state->result);
  delete state;
  if (rsqlite_on_main_thread()) {
    db_arrow_release_deferred();
  }
  stream->private_data = NULL;
  stream->release = NULL;
}

}  // namespace

void db_arrow_stream_init(
  struct ArrowArrayStream* out,
  const DbResultPtr& result,
  int64_t chunk_size
) {
  db_arrow_release_deferred();
  out->get_schema = &stream_get_schema;
  out->get_next = &stream_get_next;
  out->get_last_error = &stream_get_last_error;
  out->release = &stream_release;
  out->private_data = new StreamState(result, chunk_size);
}

bool db_arrow_stream_reads(
  struct ArrowArrayStream* stream,
  const DbResult* result
) {
  return stream->release == &stream_release &&
         get_state(stream)->result.get() == result;
}

void db_arrow_stream_read_from_cpp(struct ArrowArrayStream* stream) {
  if (stream->release == &stream_release) {
    get_state(stream)->rethrow_unwind = true;
  }
}
