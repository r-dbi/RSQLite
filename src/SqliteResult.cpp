#include <RSQLite.h>
#include "SqliteResult.h"
#include "SqliteUtils.h"

#include "affinity.h"



// Construction ////////////////////////////////////////////////////////////////

SqliteResult::SqliteResult(const SqliteConnectionPtr& pConn, const std::string& sql)
  : pConn_(pConn), pStatement_(NULL), complete_(false), ready_(false),
    nrows_(0), ncols_(0), rows_affected_(0), nparams_(0) {

  int rc = sqlite3_prepare_v2(pConn_->conn(), sql.c_str(), sql.size() + 1,
                              &pStatement_, NULL);

  if (rc != SQLITE_OK) {
    Rcpp::stop(pConn_->getException());
  }

  try {
    nparams_ = sqlite3_bind_parameter_count(pStatement_);
    if (nparams_ == 0) {
      init();
    }
  } catch (...) {
    sqlite3_finalize(pStatement_);
    pStatement_ = NULL;
    throw;
  }
}

SqliteResult::~SqliteResult() {
  try {
    sqlite3_finalize(pStatement_);
  } catch (...) {}
}


// Publics /////////////////////////////////////////////////////////////////////

bool SqliteResult::complete() {
  return complete_;
}

int SqliteResult::nrows() {
  return nrows_;
}

int SqliteResult::rows_affected() {
  return rows_affected_;
}

void SqliteResult::bind(const Rcpp::List& params) {
  if (params.size() != nparams_) {
    Rcpp::stop("Query requires %i params; %i supplied.",
               nparams_, params.size());
  }
  if (params.attr("names") == R_NilValue) {
    Rcpp::stop("Parameters must be a named list.");
  }

  for (int j = 0; j < params.size(); ++j) {
    SEXP col = params[j];
    if (Rf_length(col) != 1)
      Rcpp::stop("Parameter %i does not have length 1.", j + 1);
  }

  sqlite3_reset(pStatement_);
  sqlite3_clear_bindings(pStatement_);

  Rcpp::CharacterVector names = params.attr("names");
  for (int j = 0; j < params.size(); ++j) {
    bind_parameter(0, j, std::string(names[j]), static_cast<SEXPREC*>(params[j]));
  }

  init();
}

void SqliteResult::bind_rows(const Rcpp::List& params) {
  if (params.size() != nparams_) {
    Rcpp::stop("Query requires %i params; %i supplied.",
               nparams_, params.size());
  }
  if (params.size() == 0) {
    Rcpp::stop("Need at least one column");
  }

  SEXP first_col = params[0];
  int n = Rf_length(first_col);

  rows_affected_ = 0;

  Rcpp::CharacterVector names_ = params.attr("names");
  std::vector<std::string> names(names_.begin(), names_.end());

  for (int i = 0; i < n; ++i) {
    sqlite3_reset(pStatement_);
    sqlite3_clear_bindings(pStatement_);

    for (int j = 0; j < params.size(); ++j) {
      bind_parameter(i, j, std::string(names[j]), static_cast<SEXPREC*>(params[j]));
    }

    step();
    rows_affected_ += sqlite3_changes(pConn_->conn());
  }
}

Rcpp::List SqliteResult::fetch(const int n_max) {
  if (!ready_)
    Rcpp::stop("Query needs to be bound before fetching");

  int n = 0;
  Rcpp::List out;

  if (n_max != 0)
    out = fetch_rows(n_max, n);
  else
    out = peek_first_row();

  out = alloc_missing_cols(out, n);

  return out;
}

Rcpp::List SqliteResult::column_info() {
  peek_first_row();

  Rcpp::CharacterVector names(ncols_);
  for (int i = 0; i < ncols_; i++) {
    names[i] = names_[i];
  }

  Rcpp::CharacterVector types(ncols_);
  for (int i = 0; i < ncols_; i++) {
    switch (types_[i]) {
    case NILSXP:
    case LGLSXP:
      types[i] = "logical";
      break;
    case STRSXP:
      types[i] = "character";
      break;
    case INTSXP:
      types[i] = "integer";
      break;
    case REALSXP:
      types[i] = "double";
      break;
    case VECSXP:
      types[i] = "list";
      break;
    default:
      Rcpp::stop("Unknown variable type");
    }
  }

  Rcpp::List out = Rcpp::List::create(names, types);
  out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -ncols_);
  out.attr("class") = "data.frame";
  out.attr("names") = Rcpp::CharacterVector::create("name", "type");

  return out;
}


// Privates ////////////////////////////////////////////////////////////////////

void SqliteResult::bind_parameter(const int i, const int j0, const std::string& name, const SEXP values_) {
  if (name != "") {
    int j = find_parameter(name);
    if (j == 0)
      Rcpp::stop("No parameter with name %s.", name);
    bind_parameter_pos(i, j, values_);
  } else {
    // sqlite parameters are 1-indexed
    bind_parameter_pos(i, j0 + 1, values_);
  }
}

Rcpp::IntegerVector SqliteResult::find_params(const Rcpp::CharacterVector& param_names) {
  int p = param_names.length();
  Rcpp::IntegerVector res(p);

  for (int j = 0; j < p; ++j) {
    int pos = find_parameter(std::string(param_names[j]));
    if (pos == 0)
      pos = NA_INTEGER;
    res[j] = pos;
  }

  return res;
}

int SqliteResult::find_parameter(const std::string& name) {
  int i = 0;
  i = sqlite3_bind_parameter_index(pStatement_, name.c_str());
  if (i != 0)
    return i;

  std::string colon = ":" + name;
  i = sqlite3_bind_parameter_index(pStatement_, colon.c_str());
  if (i != 0)
    return i;

  std::string dollar = "$" + name;
  i = sqlite3_bind_parameter_index(pStatement_, dollar.c_str());
  if (i != 0)
    return i;

  return 0;
}

void SqliteResult::bind_parameter_pos(const int i, const int j, const SEXP value_) {
  // std::cerr << "TYPEOF(value_): " << TYPEOF(value_) << "\n";
  if (TYPEOF(value_) == LGLSXP) {
    Rcpp::LogicalVector value(value_);
    if (value[i] == NA_LOGICAL) {
      sqlite3_bind_null(pStatement_, j);
    } else {
      sqlite3_bind_int(pStatement_, j, static_cast<int>(value[i]));
    }
  } else if (TYPEOF(value_) == INTSXP) {
    Rcpp::IntegerVector value(value_);
    if (value[i] == NA_INTEGER) {
      sqlite3_bind_null(pStatement_, j);
    } else {
      sqlite3_bind_int(pStatement_, j, static_cast<int>(value[i]));
    }
  } else if (TYPEOF(value_) == REALSXP) {
    Rcpp::NumericVector value(value_);
    if (value[i] == NA_REAL) {
      sqlite3_bind_null(pStatement_, j);
    } else {
      sqlite3_bind_double(pStatement_, j, static_cast<double>(value[i]));
    }
  } else if (TYPEOF(value_) == STRSXP) {
    Rcpp::CharacterVector value(value_);
    if (value[i] == NA_STRING) {
      sqlite3_bind_null(pStatement_, j);
    } else {
      Rcpp::String value2 = value[i];
      std::string value3(value2);
      sqlite3_bind_text(pStatement_, j, value3.data(), value3.size(),
                        SQLITE_TRANSIENT);
    }
  } else if (TYPEOF(value_) == VECSXP) {
    SEXP raw = VECTOR_ELT(value_, i);
    if (TYPEOF(raw) != RAWSXP) {
      Rcpp::stop("Can only bind lists of raw vectors");
    }

    sqlite3_bind_blob(pStatement_, j, RAW(raw), Rf_length(raw), SQLITE_TRANSIENT);
  } else {
    Rcpp::stop("Don't know how to handle parameter of type %s.",
               Rf_type2char(TYPEOF(value_)));
  }
}

void SqliteResult::init() {
  ready_ = true;
  nrows_ = 0;
  ncols_ = sqlite3_column_count(pStatement_);
  complete_ = false;

  step();
  rows_affected_ = sqlite3_changes(pConn_->conn());
  cache_field_data();
}

void SqliteResult::step() {
  nrows_++;
  int rc = sqlite3_step(pStatement_);

  if (rc == SQLITE_DONE) {
    complete_ = true;
  } else if (rc != SQLITE_ROW) {
    Rcpp::stop(pConn_->getException());
  }
}

// We guess the correct R type for each column from the declared column type,
// if possible.  The type of the column can be amended as new values come in,
// but will be fixed after the first call to fetch().
void SqliteResult::cache_field_data() {
  types_.clear();
  names_.clear();

  int p = ncols_;
  for (int j = 0; j < p; ++j) {
    names_.push_back(sqlite3_column_name(pStatement_, j));
    types_.push_back(NILSXP);
  }
}

Rcpp::List SqliteResult::fetch_rows(const int n_max, int& n) {
  n = (n_max < 0) ? 100 : n_max;

  Rcpp::List out = dfCreate(names_, n);

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
      Rcpp::checkUserInterrupt();
  }

  // Trim back to what we actually used
  if (i < n) {
    out = dfResize(out, i);
    n = i;
  }

  return out;
}

Rcpp::List SqliteResult::peek_first_row() {
  Rcpp::List out = dfCreate(names_, 1);
  set_col_values(out, 0, 1);
  out = dfResize(out, 0);

  return out;
}

Rcpp::List SqliteResult::alloc_missing_cols(Rcpp::List data, int n) {
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

void SqliteResult::set_col_values(Rcpp::List& out, const int i, const int n) {
  for (int j = 0; j < ncols_; ++j) {
    SEXP col = out[j];
    set_col_value(col, i, j, n);
    out[j] = col;
  }
}

void SqliteResult::set_col_value(SEXP& col, const int i, const int j, const int n) {
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

SEXP SqliteResult::alloc_col(const SEXPTYPE type, const int i, const int n) {
  SEXP col = Rf_allocVector(type, n);
  PROTECT(col);
  for (int i_ = 0; i_ < i; i_++) {
    fill_default_col_value(col, i_, type);
  }
  UNPROTECT(1);
  return col;
}

void SqliteResult::fill_default_col_value(const SEXP col, const int i, const SEXPTYPE type) {
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
    SET_VECTOR_ELT(col, i, Rcpp::RawVector(0));
    break;
  }
}

void SqliteResult::fill_col_value(const SEXP col, const int i, const int j,
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

void SqliteResult::set_raw_value(const SEXP col, const int i, const int j) {
  int size = sqlite3_column_bytes(pStatement_, j);
  const void* blob = sqlite3_column_blob(pStatement_, j);

  SEXP bytes = Rf_allocVector(RAWSXP, size);
  memcpy(RAW(bytes), blob, size);

  SET_VECTOR_ELT(col, i, bytes);
}

SEXPTYPE SqliteResult::datatype_to_sexptype(const int field_type) {
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

SEXPTYPE SqliteResult::decltype_to_sexptype(const char* decl_type) {
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
