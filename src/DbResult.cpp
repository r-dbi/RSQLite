#include "pch.h"
#include "DbResult.h"
#include "DbConnection.h"
#include "DbResultImpl.h"

// Construction ////////////////////////////////////////////////////////////////

DbResult::DbResult(const DbConnectionPtr& pConn) : pConn_(pConn) {
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

int DbResult::n_rows_fetched() {
  return impl->n_rows_fetched();
}

int DbResult::n_rows_affected() {
  return impl->n_rows_affected();
}

void DbResult::bind(const cpp11::list& params) {
  validate_params(params);
  impl->bind(params);
}

cpp11::list DbResult::fetch(const int n_max) {
  if (!is_active()) {
    cpp11::stop("Inactive result set");
  }

  return impl->fetch(n_max);
}

cpp11::list DbResult::get_column_info() {
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

cpp11::strings DbResult::get_column_names() const {
  return impl->get_column_names();
}

// Arrow ///////////////////////////////////////////////////////////////////////

void DbResult::set_arrow_schema(
  const struct ArrowSchema* schema,
  const std::vector<int>& positions
) {
  if (!is_active()) {
    throw std::runtime_error("Inactive result set");
  }

  impl->set_arrow_schema(schema, positions);
}

void DbResult::arrow_schema(struct ArrowSchema* out, int64_t infer_rows) {
  if (!is_active()) {
    throw std::runtime_error("Inactive result set");
  }

  impl->arrow_schema(out, infer_rows);
}

int64_t DbResult::fetch_arrow(struct ArrowArray* out, int64_t n_max) {
  if (!is_active()) {
    throw std::runtime_error(
      "Result set was closed before the Arrow stream was consumed"
    );
  }

  return impl->fetch_arrow(out, n_max);
}

void DbResult::bind_arrow(
  struct ArrowArrayStream* stream,
  const std::vector<int>& param_indexes
) {
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
