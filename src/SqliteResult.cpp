#include "SqliteResult.h"



// Construction ////////////////////////////////////////////////////////////////

SqliteResult::SqliteResult(SqliteConnectionPtr pConn, std::string sql)
  : pStatement_(NULL), pConn_(pConn), complete_(false), ready_(false),
    nrows_(0), ncols_(0), rows_affected_(0), nparams_(0) {

  int rc = sqlite3_prepare_v2(pConn_->conn(), sql.c_str(), sql.size() + 1,
                              &pStatement_, NULL);

  if (rc != SQLITE_OK) {
    Rcpp::stop(pConn_->getException());
  }

  nparams_ = sqlite3_bind_parameter_count(pStatement_);
  if (nparams_ == 0) {
    try {
      init();
    } catch (...) {
      sqlite3_finalize(pStatement_);
      throw;
    }
  }
}

SqliteResult::~SqliteResult() {
  try {
    sqlite3_finalize(pStatement_);
  } catch (...) {}
}


// Publics /////////////////////////////////////////////////////////////////////

void SqliteResult::bind(Rcpp::List params) {
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
    bind_parameter(pStatement_, 0, j, std::string(names[j]), params[j]);
  }

  init();
}

void SqliteResult::bind_rows(Rcpp::List params) {
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
      bind_parameter(pStatement_, i, j, names[j], params[j]);
    }

    step();
    rows_affected_ += sqlite3_changes(pConn_->conn());
  }
}

Rcpp::List SqliteResult::fetch(int n_max) {
  if (!ready_)
    Rcpp::stop("Query needs to be bound before fetching");

  int n = 0;
  Rcpp::List out;

  if (n_max != 0)
    out = fetch_rows(n_max, n);
  else
    out = peek_first_row();

  // Create data for columns where all values were NULL (or for all columns
  // in the case of a 0-row data frame)
  for (int j = 0; j < ncols_; ++j) {
    if (types_[j] == NILSXP) {
      types_[j] =
        decltype_to_sexptype(sqlite3_column_decltype(pStatement_, j));
      // std::cerr << j << ": " << types_[j] << "\n";
      out[j] = alloc_col(types_[j], n, n);
    }
  }

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

Rcpp::List SqliteResult::fetch_rows(int n_max, int& n) {
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

void SqliteResult::set_col_values(Rcpp::List& out, const int i, const int n) {
  for (int j = 0; j < ncols_; ++j) {
    out[j] = set_col_value(out[j], i, j, n);
  }
}

SEXP SqliteResult::set_col_value(SEXP col, const int i, const int j, const int n) {
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
      return col;
    else {
      col = alloc_col(type, i, n);
      types_[j] = type;
    }
  }

  if (column_type == SQLITE_NULL) {
    fill_default_col_value(col, i, type);
  }
  else {
    switch (type) {
    case INTSXP:
      INTEGER(col)[i] = sqlite3_column_int(pStatement_, j);
      break;
    case REALSXP:
      REAL(col)[i] = sqlite3_column_double(pStatement_, j);
      break;
    case STRSXP:
      SET_STRING_ELT(col, i, Rf_mkCharCE((const char*) sqlite3_column_text(pStatement_, j), CE_UTF8));
      break;
    case VECSXP:
      set_raw_value(col, i, j);
      break;
    }
  }
  return col;
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

void SqliteResult::fill_default_col_value(SEXP col, const int i, const SEXPTYPE type) {
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

void SqliteResult::set_raw_value(SEXP col, const int i, const int j) {
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

  // TODO: steal sqlite3AffinityType() from sqlite3.c
  if (std::string("INTEGER") == decl_type)
    return INTSXP;
  if (std::string("REAL") == decl_type)
    return REALSXP;
  if (std::string("BLOB") == decl_type)
    return VECSXP;

  return STRSXP;
}
