#include "pch.h"
#include "DbResult.h"
#include "DbConnection.h"
#include "DbResultImpl.h"
#include "DbArrowStream.h"

namespace {

// Marks a result busy while one of its fetches or binds runs.
// R code can run meanwhile, a handler of a warning raised by the fetch, and
// must not use the statement under it: a step or a bind would free the values
// that the fetch is reading.
// The flag is reset by the destructor, also when a C++ exception leaves the
// fetch; R errors raised through cpp11 arrive as such exceptions.
class BusyScope : boost::noncopyable {
  bool& busy;

public:
  explicit BusyScope(bool& busy_) : busy(busy_) {
    if (busy) {
      throw std::runtime_error(
        "Can't use a result while one of its fetches or binds is running, "
        "as from a handler of a warning that it raised."
      );
    }
    busy = true;
  }
  ~BusyScope() {
    busy = false;
  }
};

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

bool DbResult::ready() const {
  return impl && impl->ready();
}

bool DbResult::is_active() const {
  return pConn_->is_current_result(this);
}

bool DbResult::busy() const {
  return busy_;
}

int64_t DbResult::executions() const {
  return impl->executions();
}

int DbResult::n_rows_fetched() {
  return impl->n_rows_fetched();
}

int DbResult::n_rows_affected() {
  return impl->n_rows_affected();
}

void DbResult::bind(const cpp11::list& params) {
  BusyScope busy(busy_);
  validate_params(params);
  impl->bind(params);
}

cpp11::list DbResult::fetch(const int n_max) {
  BusyScope busy(busy_);
  if (!is_active()) {
    cpp11::stop("Inactive result set");
  }

  return impl->fetch(n_max);
}

cpp11::list DbResult::get_column_info() {
  BusyScope busy(busy_);
  cpp11::writable::list out = impl->get_column_info();

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
  BusyScope busy(busy_);
  impl->arrow_schema(out, infer_rows);
}

int64_t DbResult::fetch_arrow(struct ArrowArray* out, int64_t n_max) {
  BusyScope busy(busy_);
  return impl->fetch_arrow(out, n_max);
}

void DbResult::bind_arrow(
  struct ArrowArrayStream* stream,
  const std::vector<int>& param_indexes
) {
  BusyScope busy(busy_);
  // The stream would hold a share of the result that keeps it as parameters,
  // and could never be read: the new execution invalidates it
  if (db_arrow_stream_reads(stream, this)) {
    throw std::runtime_error(
      "Can't bind a result to an Arrow stream of its own rows."
    );
  }
  impl->bind_arrow(stream, param_indexes);
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
