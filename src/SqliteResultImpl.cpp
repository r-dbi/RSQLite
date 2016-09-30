#include <RSQLite.h>
#include "SqliteResultImpl.h"
#include "SqliteUtils.h"
#include "affinity.h"



// Construction ////////////////////////////////////////////////////////////////

SqliteResultImpl::SqliteResultImpl(sqlite3* conn_, const std::string& sql)
: conn(conn_),
  stmt(prepare(conn_, sql)),
  cache(stmt),
  complete_(false),
  ready_(false),
  nrows_(0),
  rows_affected_(0),
  types_(get_initial_field_types(cache.ncols_))
{

  try {
    if (cache.nparams_ == 0) {
      after_bind();
    }
  } catch (...) {
    sqlite3_finalize(stmt);
    stmt = NULL;
    throw;
  }
}

SqliteResultImpl::_cache::_cache(sqlite3_stmt* stmt)
: names_(get_column_names(stmt)),
  ncols_(names_.size()),
  nparams_(sqlite3_bind_parameter_count(stmt))
{
}

std::vector<std::string> SqliteResultImpl::_cache::get_column_names(sqlite3_stmt* stmt) {
  int ncols = sqlite3_column_count(stmt);

  std::vector<std::string> names;
  for (int j = 0; j < ncols; ++j) {
    names.push_back(sqlite3_column_name(stmt, j));
  }

  return names;
}

SqliteResultImpl::~SqliteResultImpl() {
  try {
    sqlite3_finalize(stmt);
  } catch (...) {}
}

sqlite3_stmt* SqliteResultImpl::prepare(sqlite3* conn, const std::string& sql) {
  sqlite3_stmt* stmt = NULL;

  int rc = sqlite3_prepare_v2(conn, sql.c_str(), sql.size() + 1,
                              &stmt, NULL);
  if (rc != SQLITE_OK) {
    raise_sqlite_exception(conn);
  }

  return stmt;
}

// We guess the correct R type for each column from the declared column type,
// if possible.  The type of the column can be amended as new values come in,
// but will be fixed after the first call to fetch().
std::vector<SEXPTYPE> SqliteResultImpl::get_initial_field_types(const int ncols) {
  std::vector<SEXPTYPE> types;
  for (int j = 0; j < ncols; ++j) {
    types.push_back(NILSXP);
  }

  return types;
}

void SqliteResultImpl::after_bind() {
  ready_ = true;
  nrows_ = 0;
  complete_ = false;

  step();
}



// Publics /////////////////////////////////////////////////////////////////////

bool SqliteResultImpl::complete() {
  return complete_;
}

int SqliteResultImpl::nrows() {
  return nrows_;
}

int SqliteResultImpl::rows_affected() {
  return rows_affected_;
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

void SqliteResultImpl::bind_impl(const List& params) {
  if (params.size() != cache.nparams_) {
    stop("Query requires %i params; %i supplied.",
         cache.nparams_, params.size());
  }

  sqlite3_reset(stmt);
  sqlite3_clear_bindings(stmt);

  CharacterVector names = params.attr("names");
  for (int j = 0; j < params.size(); ++j) {
    bind_parameter(0, j, CHAR(names[j]), static_cast<SEXPREC*>(params[j]));
  }

  after_bind();
}

void SqliteResultImpl::bind_rows_impl(const List& params) {
  if (params.size() != cache.nparams_) {
    stop("Query requires %i params; %i supplied.",
         cache.nparams_, params.size());
  }

  SEXP first_col = params[0];
  int n = Rf_length(first_col);

  rows_affected_ = 0;

  CharacterVector names = params.attr("names");

  for (int i = 0; i < n; ++i) {
    sqlite3_reset(stmt);
    sqlite3_clear_bindings(stmt);

    for (int j = 0; j < params.size(); ++j) {
      bind_parameter(i, j, CHAR(names[j]), static_cast<SEXPREC*>(params[j]));
    }

    step();
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

List SqliteResultImpl::get_column_info_impl() {
  peek_first_row();

  CharacterVector names(cache.names_.begin(), cache.names_.end());

  CharacterVector types(cache.ncols_);
  for (int i = 0; i < cache.ncols_; i++) {
    types[i] = Rf_type2char(types_[i]);
  }

  return List::create(names, types);
}



// Privates ////////////////////////////////////////////////////////////////////

void SqliteResultImpl::bind_parameter(const int i, const int j0, const std::string& name, const SEXP values_) {
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

int SqliteResultImpl::find_parameter(const std::string& name) {
  int i = 0;
  i = sqlite3_bind_parameter_index(stmt, name.c_str());
  if (i != 0)
    return i;

  std::string colon = ":" + name;
  i = sqlite3_bind_parameter_index(stmt, colon.c_str());
  if (i != 0)
    return i;

  std::string dollar = "$" + name;
  i = sqlite3_bind_parameter_index(stmt, dollar.c_str());
  if (i != 0)
    return i;

  return 0;
}

void SqliteResultImpl::bind_parameter_pos(const int i, const int j, const SEXP value_) {
  // std::cerr << "TYPEOF(value_): " << TYPEOF(value_) << "\n";
  if (TYPEOF(value_) == LGLSXP) {
    LogicalVector value(value_);
    if (value[i] == NA_LOGICAL) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_int(stmt, j, static_cast<int>(value[i]));
    }
  } else if (TYPEOF(value_) == INTSXP) {
    IntegerVector value(value_);
    if (value[i] == NA_INTEGER) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_int(stmt, j, static_cast<int>(value[i]));
    }
  } else if (TYPEOF(value_) == REALSXP) {
    NumericVector value(value_);
    if (value[i] == NA_REAL) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_double(stmt, j, static_cast<double>(value[i]));
    }
  } else if (TYPEOF(value_) == STRSXP) {
    CharacterVector value(value_);
    if (value[i] == NA_STRING) {
      sqlite3_bind_null(stmt, j);
    } else {
      String value2 = value[i];
      std::string value3(value2);
      sqlite3_bind_text(stmt, j, value3.data(), value3.size(),
                        SQLITE_TRANSIENT);
    }
  } else if (TYPEOF(value_) == VECSXP) {
    SEXP raw = VECTOR_ELT(value_, i);
    if (TYPEOF(raw) != RAWSXP) {
      stop("Can only bind lists of raw vectors");
    }

    sqlite3_bind_blob(stmt, j, RAW(raw), Rf_length(raw), SQLITE_TRANSIENT);
  } else {
    stop("Don't know how to handle parameter of type %s.",
               Rf_type2char(TYPEOF(value_)));
  }
}

List SqliteResultImpl::fetch_rows(const int n_max, int& n) {
  n = (n_max < 0) ? 100 : n_max;

  List out = dfCreate(cache.names_, n);

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
  int rc = sqlite3_step(stmt);

  if (rc == SQLITE_DONE) {
    complete_ = true;
  } else if (rc != SQLITE_ROW) {
    raise_sqlite_exception();
  }

  rows_affected_ += sqlite3_changes(conn);
}

List SqliteResultImpl::peek_first_row() {
  List out = dfCreate(cache.names_, 1);
  set_col_values(out, 0, 1);
  out = dfResize(out, 0);

  return out;
}

List SqliteResultImpl::alloc_missing_cols(List data, int n) {
  // Create data for columns where all values were NULL (or for all columns
  // in the case of a 0-row data frame)
  for (int j = 0; j < cache.ncols_; ++j) {
    if (types_[j] == NILSXP) {
      types_[j] =
      decltype_to_sexptype(sqlite3_column_decltype(stmt, j));
      // std::cerr << j << ": " << types_[j] << "\n";
      data[j] = alloc_col(types_[j], n, n);
    }
  }
  return data;
}

void SqliteResultImpl::set_col_values(List& out, const int i, const int n) {
  for (int j = 0; j < cache.ncols_; ++j) {
    SEXP col = out[j];
    set_col_value(col, i, j, n);
    out[j] = col;
  }
}

void SqliteResultImpl::set_col_value(SEXP& col, const int i, const int j, const int n) {
  SEXPTYPE type = types_[j];
  int column_type = sqlite3_column_type(stmt, j);

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
    fill_default_col_value(col, i);
  }
  else {
    fill_col_value(col, i, j);
  }
  return;
}

SEXP SqliteResultImpl::alloc_col(const SEXPTYPE type, const int i, const int n) {
  SEXP col = Rf_allocVector(type, n);
  PROTECT(col);
  for (int i_ = 0; i_ < i; i_++) {
    fill_default_col_value(col, i_);
  }
  UNPROTECT(1);
  return col;
}

void SqliteResultImpl::fill_default_col_value(const SEXP col, const int i) {
  switch (TYPEOF(col)) {
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

void SqliteResultImpl::fill_col_value(const SEXP col, const int i, const int j) {
  switch (TYPEOF(col)) {
  case INTSXP:
    set_int_value(col, i, j);
    break;
  case REALSXP:
    set_real_value(col, i, j);
    break;
  case STRSXP:
    set_string_value(col, i, j);
    break;
  case VECSXP:
    set_raw_value(col, i, j);
    break;
  }
}

void SqliteResultImpl::set_int_value(const SEXP col, const int i, const int j) const {
  INTEGER(col)[i] = sqlite3_column_int(stmt, j);
}

void SqliteResultImpl::set_real_value(const SEXP col, const int i, const int j) const {
  REAL(col)[i] = sqlite3_column_double(stmt, j);
}

void SqliteResultImpl::set_string_value(const SEXP col, const int i, const int j) const {
  const char* const text = reinterpret_cast<const char*>(sqlite3_column_text(stmt, j));
  SET_STRING_ELT(col, i, Rf_mkCharCE(text, CE_UTF8));
}

void SqliteResultImpl::set_raw_value(const SEXP col, const int i, const int j) const {
  int size = sqlite3_column_bytes(stmt, j);
  const void* blob = sqlite3_column_blob(stmt, j);

  SEXP bytes = Rf_allocVector(RAWSXP, size);
  memcpy(RAW(bytes), blob, size);

  SET_VECTOR_ELT(col, i, bytes);
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

void SqliteResultImpl::raise_sqlite_exception() const {
  raise_sqlite_exception(conn);
}

void SqliteResultImpl::raise_sqlite_exception(sqlite3* conn) {
  stop(sqlite3_errmsg(conn));
}
