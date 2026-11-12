#include "pch.h"
#include "DbResult.h"
#include "DbConnection.h"
#include "DbResultImpl.h"
#include <exception>
#include <stdexcept>
#include <type_traits>

namespace {

// Marks a result busy while one of its fetches or binds runs,
// or while its column info reads the first row.
// R code can run meanwhile, a handler of a warning raised by the fetch or a
// busy handler, and must not use the statement under it:
// clearing the result would free the statement that the fetch goes on with,
// and a step or a bind would free the values that the fetch is reading.
// R_ExecWithCleanup() resets the flag when the body returns, and also when an
// R error leaves the body by a longjmp instead of through cpp11,
// such as a failed allocation in R's API.
// Such a longjmp still skips the C++ destructors of the body,
// and can leave the statement in the middle of a step.
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
  busy = true;
  typedef typename std::remove_reference<F>::type Body;
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

DbResult::DbResult(const DbConnectionPtr& pConn) : pConn_(pConn), busy_(false) {
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

bool DbResult::is_active() const {
  return pConn_->is_current_result(this);
}

bool DbResult::busy() const {
  return busy_;
}

int DbResult::n_rows_fetched() {
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

void DbResult::fetch_arrow_chunk(
  struct ArrowArray* array,
  struct ArrowSchema* schema,
  const int n_max
) {
  run_guarded(busy_, [&] {
    if (!is_active()) {
      cpp11::stop("Inactive result set");
    }
    impl->fetch_arrow_chunk(array, schema, n_max);
  });
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
