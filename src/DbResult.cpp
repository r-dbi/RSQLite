#include "pch.h"
#include "DbResult.h"
#include "DbConnection.h"
#include "DbResultImpl.h"
#include "DbArrowStream.h"
#include "main_thread.h"

#include <exception>
#include <type_traits>

namespace {

// Marks a result busy while one of its fetches or binds runs.
// R code can run meanwhile, a handler of a warning raised by the fetch, and
// must not use the statement under it: a step or a bind would free the values
// that the fetch is reading.
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
  *static_cast<bool*>(data) = false;
}

template <typename F>
void run_guarded(bool& busy, F&& body) {
  if (busy) {
    throw std::runtime_error(
      "Can't use a result while one of its fetches or binds is running, "
      "as from a handler of a warning that it raised."
    );
  }
  typedef typename std::remove_reference<F>::type Body;
  busy = true;
  if (!rsqlite_on_main_thread()) {
    // An Arrow stream read on another thread calls no R API, nothing can
    // longjmp: a scoped reset is enough, and R_ExecWithCleanup() is not allowed
    struct Reset {
      bool& busy;
      ~Reset() {
        busy = false;
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
    : pConn_(pConn), busy_(false), rethrown_unwinds_(0) {
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

bool DbResult::busy() const {
  return busy_;
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

// Arrow ///////////////////////////////////////////////////////////////////////

// No is_active() check, unlike fetch(): a lazy Arrow stream reads on after the
// R result object has been cleared and while other results are in use on the
// connection, see db_arrow_stream_init()

void DbResult::arrow_schema(struct ArrowSchema* out, int64_t infer_rows) {
  run_guarded(busy_, [&] { impl->arrow_schema(out, infer_rows); });
}

int64_t DbResult::fetch_arrow(struct ArrowArray* out, int64_t n_max) {
  int64_t n = 0;
  run_guarded(busy_, [&] { n = impl->fetch_arrow(out, n_max); });
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
