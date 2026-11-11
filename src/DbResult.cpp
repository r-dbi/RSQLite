#include "pch.h"
#include "DbResult.h"
#include "DbConnection.h"
#include "DbResultImpl.h"
#include "DbArrowStream.h"
#include "main_thread.h"

#include <exception>
#include <type_traits>

namespace {

// Marks a result busy while one of its fetches or binds runs, with the thread
// that runs it: R's main thread, or another thread that reads an Arrow stream
// of the result, as arrow's scanner and Acero do in the background while R
// goes on. The mark is taken by an atomic exchange, so that two threads are
// never in a result at once: the second one fails with an error that names the
// first. It could wait for the first one instead, which this design leaves
// open.
// On R's main thread, R code can run while the mark is held, a handler of a
// warning raised by the fetch, and must not use the statement under it: a step
// or a bind would free the values that the fetch is reading.
// R_ExecWithCleanup() resets the flag when the body returns, and also when an
// R error leaves the body by a longjmp instead of through cpp11: a raw
// allocation that fails, an ALTREP parameter, a parameter stream of another
// package that calls R. Such a longjmp still skips the C++ destructors of the
// body, and can leave the statement in the middle of a step.
// C++ exceptions are caught inside the body and rethrown after
// R_ExecWithCleanup() has returned, so that none crosses R's C frames.
struct GuardedCall {
  void (*run)(void*);
  void* body;
  std::exception_ptr error;
};

SEXP guarded_body(void* data) {
  GuardedCall* call = static_cast<GuardedCall*>(data);
  try {
    call->run(call->body);
  } catch (...) {
    call->error = std::current_exception();
  }
  return R_NilValue;
}

void guarded_cleanup(void* data) {
  static_cast<std::atomic<int>*>(data)->store(DbResult::BUSY_NONE);
}

const char* busy_message(int holder, bool on_main_thread) {
  if (on_main_thread) {
    if (holder == DbResult::BUSY_MAIN_THREAD) {
      return "Can't use a result while one of its fetches or binds is "
             "running, as from a handler of a warning that it raised.";
    }
    return "Can't use a result while its Arrow stream is being read on "
           "another thread, for example by arrow's scanner or Acero.";
  }
  if (holder == DbResult::BUSY_MAIN_THREAD) {
    return "Can't read the Arrow stream while R's main thread fetches from or "
           "binds its result.";
  }
  return "Can't read the Arrow stream while another thread reads an Arrow "
         "stream of its result.";
}

template <typename F>
void run_guarded(std::atomic<int>& busy, F&& body) {
  const bool on_main_thread = rsqlite_on_main_thread();
  int holder = DbResult::BUSY_NONE;
  if (!busy.compare_exchange_strong(
        holder,
        on_main_thread ? DbResult::BUSY_MAIN_THREAD
                       : DbResult::BUSY_OTHER_THREAD
      )) {
    throw std::runtime_error(busy_message(holder, on_main_thread));
  }
  typedef typename std::remove_reference<F>::type Body;
  if (!on_main_thread) {
    // An Arrow stream read on another thread calls no R API, nothing can
    // longjmp: a scoped reset is enough, and R_ExecWithCleanup() is not allowed
    struct Reset {
      std::atomic<int>& busy;
      ~Reset() {
        busy.store(DbResult::BUSY_NONE);
      }
    } reset = { busy };
    body();
    return;
  }
  GuardedCall call = { [](void* f) { (*static_cast<Body*>(f))(); },
                       &body,
                       std::exception_ptr() };
  R_ExecWithCleanup(guarded_body, &call, guarded_cleanup, &busy);
  if (call.error) {
    std::rethrow_exception(call.error);
  }
}

}  // namespace

// Construction ////////////////////////////////////////////////////////////////

DbResult::DbResult(const DbConnectionPtr& pConn)
    : pConn_(pConn), busy_(BUSY_NONE), rethrown_unwinds_(0) {
  pConn_->check_connection();

  // subclass constructor can throw, the destructor will remove the
  // current result set
  pConn_->set_current_result(this);
}

DbResult::~DbResult() {
  try {
    if (is_active()) {
      pConn_->reset_current_result(this);
    }
  } catch (...) {}
}

// Publics /////////////////////////////////////////////////////////////////////

bool DbResult::complete() const {
  return (impl == NULL) || impl->complete();
}

bool DbResult::ready() const {
  return impl && impl->ready();
}

bool DbResult::is_active() const {
  return pConn_->is_current_result(this);
}

DbResult::BusyOwner DbResult::busy_owner() const {
  return static_cast<BusyOwner>(busy_.load());
}

void DbResult::hold_busy(std::function<void()> body) {
  run_guarded(busy_, body);
}

void DbResult::finalize_statement() {
  if (impl) {
    impl->finalize_statement();
  }
}

void DbResult::count_rethrown_unwind() {
  ++rethrown_unwinds_;
}

int64_t DbResult::rethrown_unwinds() const {
  return rethrown_unwinds_;
}

int64_t DbResult::executions() const {
  return impl->executions();
}

int64_t DbResult::n_rows_fetched() {
  return impl->n_rows_fetched();
}

int DbResult::n_rows_affected() {
  return impl->n_rows_affected();
}

void DbResult::bind(const cpp11::list& params) {
  run_guarded(busy_, [&] {
    validate_params(params);
    impl->bind(params);
  });
}

cpp11::list DbResult::fetch(const int n_max) {
  cpp11::list out;
  run_guarded(busy_, [&] {
    if (!is_active()) {
      cpp11::stop("Inactive result set");
    }
    out = impl->fetch(n_max);
  });
  return out;
}

cpp11::list DbResult::get_column_info() {
  cpp11::writable::list out;
  run_guarded(busy_, [&] { out = impl->get_column_info(); });

  out.attr("row.names") = cpp11::integers({ NA_INTEGER, -Rf_length(out[0]) });
  out.attr("class") = "data.frame";

  return out;
}

void DbResult::close() {
  // Called from destructor
  if (impl) {
    impl->close();
  }
}

cpp11::strings DbResult::get_column_names() {
  cpp11::strings out;
  run_guarded(busy_, [&] { out = impl->get_column_names(); });
  return out;
}

// Arrow ///////////////////////////////////////////////////////////////////////

void DbResult::set_arrow_schema(
  const struct ArrowSchema* schema,
  const std::vector<int>& positions,
  const std::vector<bool>& seconds
) {
  run_guarded(busy_, [&] {
    if (!is_active()) {
      throw std::runtime_error("Inactive result set");
    }

    impl->set_arrow_schema(schema, positions, seconds);
  });
}

// No is_active() check, unlike fetch(): a lazy Arrow stream reads on after the
// R result object has been cleared and while other results are in use on the
// connection, see db_arrow_stream_init()

void DbResult::arrow_schema(
  struct ArrowSchema* out,
  int64_t infer_rows,
  int64_t stream_execution
) {
  precheck_stream_execution(stream_execution);
  run_guarded(busy_, [&] {
    check_stream_execution(stream_execution);
    impl->arrow_schema(out, infer_rows);
  });
}

int64_t DbResult::fetch_arrow(
  struct ArrowArray* out,
  int64_t n_max,
  int64_t stream_execution,
  bool* complete
) {
  int64_t n = 0;
  precheck_stream_execution(stream_execution);
  run_guarded(busy_, [&] {
    check_stream_execution(stream_execution);
    n = impl->fetch_arrow(out, n_max);
    if (complete != NULL) {
      *complete = impl->complete();
    }
  });
  return n;
}

int64_t DbResult::fetch_arrow_df(
  struct ArrowArrayStream* out,
  ArrowDfColumns& columns,
  int64_t n_max,
  int64_t chunk_size
) {
  int64_t n = 0;
  run_guarded(busy_, [&] {
    nanoarrow::UniqueSchema schema;
    std::vector<nanoarrow::UniqueArray> chunks;
    n = impl->fetch_arrow_df(schema.get(), chunks, columns, n_max, chunk_size);
    db_arrow_buffered_stream_init(out, schema, chunks);
  });
  return n;
}

void DbResult::bind_arrow(
  struct ArrowArrayStream* stream,
  const std::vector<int>& param_indexes
) {
  run_guarded(busy_, [&] {
    // The stream would hold a share of the result that keeps it as
    // parameters, and could never be read: the new execution invalidates it
    if (db_arrow_stream_reads(stream, this)) {
      throw std::runtime_error(
        "Can't bind a result to an Arrow stream of its own rows."
      );
    }
    impl->bind_arrow(stream, param_indexes);
  });
}

// Privates ///////////////////////////////////////////////////////////////////

// New parameters execute the statement again, with new rows and possibly
// other types than those of the schema that a stream handed out.
// Called inside the busy mark, where no bind runs on another thread
void DbResult::check_stream_execution(int64_t stream_execution) const {
  if (stream_execution >= 0 && impl->executions() != stream_execution) {
    throw std::runtime_error(
      "The result was bound to new parameters after the Arrow stream was "
      "created, call dbFetchArrow() again"
    );
  }
}

// Only R's main thread binds, so there the check needs no busy mark: a stream
// that a bind of the result itself reads fails with this message rather than
// with the one of the busy mark
void DbResult::precheck_stream_execution(int64_t stream_execution) const {
  if (rsqlite_on_main_thread()) {
    check_stream_execution(stream_execution);
  }
}

void DbResult::validate_params(const cpp11::list& params) const {
  if (params.size() != 0) {
    SEXP first_col = cpp11::as_sexp(params[0]);
    int n = Rf_length(first_col);

    for (int j = 1; j < params.size(); ++j) {
      SEXP col = cpp11::as_sexp(params[j]);
      if (Rf_length(col) != n) {
        cpp11::stop("Parameter %i does not have length %d.", j + 1, n);
      }
    }
  }
}
