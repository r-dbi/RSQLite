//
// Created by muelleki on 30.09.16.
//

#include "SqliteResult.h"
#include <RSQLite.h>
#include "SqliteResultImpl.h"

SqliteResultImpl::~SqliteResultImpl() {
  try {
    sqlite3_finalize(pStatement_);
  } catch (...) {}
}

void SqliteResultImpl::prepare(const std::__cxx11::string& sql) {
  int rc = sqlite3_prepare_v2(SqliteResult::pConn_->conn(), sql.c_str(), sql.size() + 1,
                              &pStatement_, NULL);
  if (rc != SQLITE_OK) {
    stop(SqliteResult::pConn_->getException());
  }
}

void SqliteResultImpl::init_if_bound() {
  nparams_ = sqlite3_bind_parameter_count(pStatement_);
  if (nparams_ == 0) {
    init();
  }
}

void SqliteResultImpl::init() {
  ready_ = true;
  nrows_ = 0;
  ncols_ = sqlite3_column_count(pStatement_);
  complete_ = false;

  step();
  rows_affected_ = sqlite3_changes(SqliteResult::pConn_->conn());
  cache_field_data();
}

// We guess the correct R type for each column from the declared column type,
// if possible.  The type of the column can be amended as new values come in,
// but will be fixed after the first call to fetch().
void SqliteResultImpl::cache_field_data() {
  types_.clear();
  names_.clear();

  int p = ncols_;
  for (int j = 0; j < p; ++j) {
    names_.push_back(sqlite3_column_name(pStatement_, j));
    types_.push_back(NILSXP);
  }
}

void SqliteResultImpl::bind_impl(const List& params) {
  sqlite3_reset(pStatement_);
  sqlite3_clear_bindings(pStatement_);

  CharacterVector names = params.attr("names");
  for (int j = 0; j < params.size(); ++j) {
    bind_parameter(0, j, CHAR(names[j]), static_cast<SEXPREC*>(params[j]));
  }
}

void SqliteResultImpl::bind_rows_impl(const List& params) {
  SEXP first_col = params[0];
  int n = Rf_length(first_col);

  rows_affected_ = 0;

  CharacterVector names = params.attr("names");

  for (int i = 0; i < n; ++i) {
    sqlite3_reset(pStatement_);
    sqlite3_clear_bindings(pStatement_);

    for (int j = 0; j < params.size(); ++j) {
      bind_parameter(i, j, CHAR(names[j]), static_cast<SEXPREC*>(params[j]));
    }

    step();
    rows_affected_ += sqlite3_changes(SqliteResult::pConn_->conn());
  }
}

void SqliteResultImpl::bind_parameter(const int i, const int j0, const std::__cxx11::string& name, const SEXP values_) {
  if (name != "") {
    int j = find_parameter(name);
    if (j == 0)
      stop("No parameter with name %s.", name);
    bind_parameter_pos(i, j, values_);
  } else {
    // sqlite parameters are 1-indexed
    bind_parameter_pos(i, j0 + 1, values_);
  }
}

IntegerVector SqliteResultImpl::find_params_impl(const CharacterVector& param_names) {
  int p = param_names.length();
  IntegerVector res(p);

  for (int j = 0; j < p; ++j) {
    int pos = find_parameter(CHAR(param_names[j]));
    if (pos == 0)
      pos = NA_INTEGER;
    res[j] = pos;
  }

  return res;
}

int SqliteResultImpl::find_parameter(const std::__cxx11::string& name) {
  int i = 0;
  i = sqlite3_bind_parameter_index(pStatement_, name.c_str());
  if (i != 0)
    return i;

  std::__cxx11::string colon = ":" + name;
  i = sqlite3_bind_parameter_index(pStatement_, colon.c_str());
  if (i != 0)
    return i;

  std::__cxx11::string dollar = "$" + name;
  i = sqlite3_bind_parameter_index(pStatement_, dollar.c_str());
  if (i != 0)
    return i;

  return 0;
}

void SqliteResultImpl::bind_parameter_pos(const int i, const int j, const SEXP value_) {
  // std::cerr << "TYPEOF(value_): " << TYPEOF(value_) << "\n";
  if (TYPEOF(value_) == LGLSXP) {
    LogicalVector value(value_);
    if (value[i] == NA_LOGICAL) {
      sqlite3_bind_null(pStatement_, j);
    } else {
      sqlite3_bind_int(pStatement_, j, static_cast<int>(value[i]));
    }
  } else if (TYPEOF(value_) == INTSXP) {
    IntegerVector value(value_);
    if (value[i] == NA_INTEGER) {
      sqlite3_bind_null(pStatement_, j);
    } else {
      sqlite3_bind_int(pStatement_, j, static_cast<int>(value[i]));
    }
  } else if (TYPEOF(value_) == REALSXP) {
    NumericVector value(value_);
    if (value[i] == NA_REAL) {
      sqlite3_bind_null(pStatement_, j);
    } else {
      sqlite3_bind_double(pStatement_, j, static_cast<double>(value[i]));
    }
  } else if (TYPEOF(value_) == STRSXP) {
    CharacterVector value(value_);
    if (value[i] == NA_STRING) {
      sqlite3_bind_null(pStatement_, j);
    } else {
      String value2 = value[i];
      std::__cxx11::string value3(value2);
      sqlite3_bind_text(pStatement_, j, value3.data(), value3.size(),
                        SQLITE_TRANSIENT);
    }
  } else if (TYPEOF(value_) == VECSXP) {
    SEXP raw = VECTOR_ELT(value_, i);
    if (TYPEOF(raw) != RAWSXP) {
      stop("Can only bind lists of raw vectors");
    }

    sqlite3_bind_blob(pStatement_, j, RAW(raw), Rf_length(raw), SQLITE_TRANSIENT);
  } else {
    stop("Don't know how to handle parameter of type %s.",
               Rf_type2char(TYPEOF(value_)));
  }
}

List SqliteResultImpl::fetch_impl(const int n_max) {
  if (!ready_)
    stop("Query needs to be bound before fetching");

  int n = 0;
  List out;

  if (n_max != 0)
    out = fetch_rows(n_max, n);
  else
    out = peek_first_row();

  out = alloc_missing_cols(out, n);

  return out;
}

List SqliteResultImpl::fetch_rows(const int n_max, int& n) {
  n = (n_max < 0) ? 100 : n_max;

  List out = dfCreate(names_, n);

  int i = 0;
  while (!complete_) {
    if (i >= n) {
      if (n_max < 0) {
        n *= 2;
        out = dfResize(out, n);
      } else {
        break;
      }
    }

    set_col_values(out, i, n);
    step();
    ++i;

    if (i % 1000 == 0)
      checkUserInterrupt();
  }

  // Trim back to what we actually used
  if (i < n) {
    out = dfResize(out, i);
    n = i;
  }

  return out;
}

void SqliteResultImpl::step() {
  nrows_++;
  int rc = sqlite3_step(pStatement_);

  if (rc == SQLITE_DONE) {
    complete_ = true;
  } else if (rc != SQLITE_ROW) {
    stop(SqliteResult::pConn_->getException());
  }
}

List SqliteResultImpl::peek_first_row() {
  List out = dfCreate(names_, 1);
  set_col_values(out, 0, 1);
  out = dfResize(out, 0);

  return out;
}

List SqliteResultImpl::alloc_missing_cols(List data, int n) {
  // Create data for columns where all values were NULL (or for all columns
  // in the case of a 0-row data frame)
  for (int j = 0; j < ncols_; ++j) {
    if (types_[j] == NILSXP) {
      types_[j] =
      decltype_to_sexptype(sqlite3_column_decltype(pStatement_, j));
      // std::cerr << j << ": " << types_[j] << "\n";
      data[j] = alloc_col(types_[j], n, n);
    }
  }
  return data;
}

void SqliteResultImpl::set_col_values(List& out, const int i, const int n) {
  for (int j = 0; j < ncols_; ++j) {
    SEXP col = out[j];
    set_col_value(col, i, j, n);
    out[j] = col;
  }
}

void SqliteResultImpl::set_col_value(SEXP& col, const int i, const int j, const int n) {
  SEXPTYPE type = types_[j];
  int column_type = sqlite3_column_type(pStatement_, j);

  // std::cerr << "column_type: " << column_type << "\n";
  // std::cerr << "type: " << type << "\n";

  if (type == NILSXP) {
    // std::cerr << "datatype_to_sexptype\n";
    type = datatype_to_sexptype(column_type);
    // std::cerr << "type: " << type << "\n";
  }

  if (Rf_isNull(col)) {
    if (type == NILSXP)
      return;
    else {
      col = alloc_col(type, i, n);
      types_[j] = type;
    }
  }

  if (column_type == SQLITE_NULL) {
    fill_default_col_value(col, i, type);
  }
  else {
    fill_col_value(col, i, j, type);
  }
  return;
}

SEXP SqliteResultImpl::alloc_col(const SEXPTYPE type, const int i, const int n) {
  SEXP col = Rf_allocVector(type, n);
  PROTECT(col);
  for (int i_ = 0; i_ < i; i_++) {
    fill_default_col_value(col, i_, type);
  }
  UNPROTECT(1);
  return col;
}

void SqliteResultImpl::fill_default_col_value(const SEXP col, const int i, const SEXPTYPE type) {
  switch (type) {
  case LGLSXP:
    LOGICAL(col)[i] = NA_LOGICAL;
    break;
  case INTSXP:
    INTEGER(col)[i] = NA_INTEGER;
    break;
  case REALSXP:
    REAL(col)[i] = NA_REAL;
    break;
  case STRSXP:
    SET_STRING_ELT(col, i, NA_STRING);
    break;
  case VECSXP:
    SET_VECTOR_ELT(col, i, RawVector(0));
    break;
  }
}

void SqliteResultImpl::fill_col_value(const SEXP col, const int i, const int j,
                                      SEXPTYPE type) {
  switch (type) {
  case INTSXP:
    INTEGER(col)[i] = sqlite3_column_int(pStatement_, j);
    break;
  case REALSXP:
    REAL(col)[i] = sqlite3_column_double(pStatement_, j);
    break;
  case STRSXP:
    SET_STRING_ELT(col, i,
                   Rf_mkCharCE((const char*) sqlite3_column_text(pStatement_, j),
                               CE_UTF8));
    break;
  case VECSXP:
    set_raw_value(col, i, j);
    break;
  }
}

void SqliteResultImpl::set_raw_value(const SEXP col, const int i, const int j) {
  int size = sqlite3_column_bytes(pStatement_, j);
  const void* blob = sqlite3_column_blob(pStatement_, j);

  SEXP bytes = Rf_allocVector(RAWSXP, size);
  memcpy(RAW(bytes), blob, size);

  SET_VECTOR_ELT(col, i, bytes);
}

List SqliteResultImpl::get_column_info_impl() {
  peek_first_row();

  CharacterVector names(ncols_);
  for (int i = 0; i < ncols_; i++) {
    names[i] = names_[i];
  }

  CharacterVector types(ncols_);
  for (int i = 0; i < ncols_; i++) {
    types[i] = Rf_type2char(types_[i]);
  }

  return ::Rcpp::Vector<19>::create(names, types);
}

SEXPTYPE SqliteResultImpl::datatype_to_sexptype(const int field_type) {
  switch (field_type) {
  case SQLITE_INTEGER:
    return INTSXP;

  case SQLITE_FLOAT:
    return REALSXP;

  case SQLITE_TEXT:
    return STRSXP;

  case SQLITE_BLOB:
    // List of raw vectors
    return VECSXP;

  case SQLITE_NULL:
  default:
    return NILSXP;
  }
}

SEXPTYPE SqliteResultImpl::decltype_to_sexptype(const char* decl_type) {
  if (decl_type == NULL)
    return LGLSXP;

  char affinity = sqlite3AffinityType(decl_type);

  switch (affinity) {
  case SQLITE_AFF_INTEGER:
    return INTSXP;

  case SQLITE_AFF_NUMERIC:
  case SQLITE_AFF_REAL:
    return REALSXP;

  case SQLITE_AFF_TEXT:
    return STRSXP;

  case SQLITE_AFF_BLOB:
    return VECSXP;
  }

  // Shouldn't occur
  return LGLSXP;
}