#include <Rcpp.h>
#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include "sqlite3.h"

void inline set_col_value(SEXP col, SEXPTYPE type, sqlite3_stmt* pStatement_, int i, int j) {
  switch(type) {
  case INTSXP:
    if (sqlite3_column_type(pStatement_, j) == SQLITE_NULL) {
      INTEGER(col)[i] = NA_INTEGER;
    } else {
      INTEGER(col)[i] = sqlite3_column_int(pStatement_, j);
    }
    break;
  case REALSXP:
    if (sqlite3_column_type(pStatement_, j) == SQLITE_NULL) {
      REAL(col)[i] = NA_REAL;
    } else {
      REAL(col)[i] = sqlite3_column_double(pStatement_, j);
    }
    break;
  case STRSXP:
    if (sqlite3_column_type(pStatement_, j) == SQLITE_NULL) {
      SET_STRING_ELT(col, i, NA_STRING);
    } else {
      SET_STRING_ELT(col, i, Rf_mkCharCE((const char*) sqlite3_column_text(pStatement_, j), CE_UTF8));
    }
    break;
  case RAWSXP:
    // Something with memcpy & RAW?
    break;
  }
}

Rcpp::List inline df_resize(Rcpp::List df, int n) {
  int p = df.size();
  
  Rcpp::List out(p);
  for (int j = 0; j < p; ++j) {
    out[j] = Rf_lengthgets(df[j], n);
  }
  
  return out;
}

Rcpp::List inline df_create(std::vector<SEXPTYPE> types, int n) {
  int p = types.size();
  
  Rcpp::List out(p);
  for (int j = 0; j < p; ++j) {
    out[j] = Rf_allocVector(types[j], n);
  }
  return out;
}

int inline find_parameter(sqlite3_stmt* stmt, std::string name) {
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

void inline bind_parameter(sqlite3_stmt* stmt, int i, std::string name, SEXP value_) {
  if (name != "") {
    i = find_parameter(stmt, name);
    if (i == 0)
      Rcpp::stop("No parameter with name %s.", name);
  } else {
    i++; // sqlite parameters are 1-indexed
  }

  if (Rf_length(value_) != 1)
    Rcpp::stop("Parameter %i does not have length 1.", i);

  if (TYPEOF(value_) == LGLSXP) {
    Rcpp::LogicalVector value(value_);
    if (value[0] == NA_LOGICAL) {
      sqlite3_bind_null(stmt, i);
    } else {
      sqlite3_bind_int(stmt, i, value[0]);
    }
  } else if (TYPEOF(value_) == INTSXP) {
    Rcpp::IntegerVector value(value_);
    if (value[0] == NA_INTEGER) {
      sqlite3_bind_null(stmt, i);
    } else {
      sqlite3_bind_int(stmt, i, value[0]);
    }
  } else if (TYPEOF(value_) == REALSXP) {
    Rcpp::NumericVector value(value_);
    if (value[0] == NA_REAL) {
      sqlite3_bind_null(stmt, i);
    } else {
      sqlite3_bind_double(stmt, i, value[0]);
    }
  } else if (TYPEOF(value_) == STRSXP) {
    Rcpp::CharacterVector value(value_);
    if (value[0] == NA_STRING) {
      sqlite3_bind_null(stmt, i);
    } else {
      Rcpp::String value2 = value[0];
      std::string value3(value2);
      sqlite3_bind_text(stmt, i, value3.c_str(), value3.size() + 1, 
        SQLITE_TRANSIENT);
    }
  } else {
    Rcpp::stop("Don't know how to handle parameter of type %s.", 
      Rf_type2char(TYPEOF(value_)));
  }
}

// Connection ------------------------------------------------------------------

// Reference counted wrapper for a sqlite3* connnection which will keep the
// connection alive as long as there are references to this object alive.

// convenience typedef for shared_ptr to SqliteConnectionWrapper
class SqliteConnectionWrapper;
typedef boost::shared_ptr<SqliteConnectionWrapper> SqliteConnectionPtr;

class SqliteConnectionWrapper : boost::noncopyable {
public:
  // Create a new connection handle
  SqliteConnectionWrapper(std::string path, bool allow_ext, 
                          int flags, std::string vfs = "")
      : pConn_(NULL) {
    
    // Get the underlying database connection
    int rc = sqlite3_open_v2(path.c_str(), &pConn_, flags, vfs.size() ? vfs.c_str() : NULL);
    if (rc != SQLITE_OK) {
      Rcpp::stop("Could not connect to database:\n%s", getException());
    }
    if (allow_ext) {
      sqlite3_enable_load_extension(pConn_, 1);
    }
  }
  
  void copy_to(SqliteConnectionPtr pDest) {
    sqlite3_backup* backup = sqlite3_backup_init(pDest->conn(), "main", 
      pConn_, "main");

    int rc = sqlite3_backup_step(backup, -1);
    if (rc != SQLITE_DONE) {
      Rcpp::stop("Failed to copy all data:\n%s", getException());
    }
    rc = sqlite3_backup_finish(backup);
    if (rc != SQLITE_OK) {
      Rcpp::stop("Could not finish copy:\n%s", getException());
    }
  }
  
  virtual ~SqliteConnectionWrapper() {
    try {
      sqlite3_close_v2(pConn_); 
    } catch(...) {}
  }

  
  // Get access to the underlying sqlite3*
  sqlite3* conn() const { return pConn_; }
  
  // Get the last exception as a string
  std::string getException() const {
    if (pConn_ != NULL)
      return std::string(sqlite3_errmsg(pConn_));
    else
      return std::string();
  }
  
private:
  sqlite3* pConn_;
};

// Result ----------------------------------------------------------------------

class SqliteResult : boost::noncopyable {
  sqlite3_stmt* pStatement_;
  SqliteConnectionPtr pConn_;
  bool complete_, ready_;
  int nrows_, ncols_, rows_affected_, nparams_;
  std::vector<SEXPTYPE> types_;
  std::vector<std::string> names_;
  
public:
  SqliteResult(SqliteConnectionPtr pConn, std::string sql)
    : pStatement_(NULL), pConn_(pConn), complete_(false), ready_(false),
      nrows_(0), ncols_(0), rows_affected_(0), nparams_(0) {
    
    int rc = sqlite3_prepare_v2(pConn_->conn(), sql.c_str(), sql.size() + 1, 
      &pStatement_, NULL);
    
    if (rc != SQLITE_OK) {
      Rcpp::stop(pConn_->getException());
    }
    
    nparams_ = sqlite3_bind_parameter_count(pStatement_);
    if (nparams_ == 0) {
      init();
    }
  }
  
  void init() {
    ready_ = true;
    nrows_ = 0;
    ncols_ = sqlite3_column_count(pStatement_);
    complete_ = false;
    
    step();
    rows_affected_ = sqlite3_changes(pConn_->conn());
    cache_field_data();
  }
  
  void bind(Rcpp::List params) {
    if (params.size() != nparams_) {
      Rcpp::stop("Query requires %i params; %i supplied.",
        nparams_, params.size());
    }
    if (params.attr("names") == R_NilValue) {
      Rcpp::stop("Parameters must be a named list.");
    }
    
    sqlite3_reset(pStatement_);
    sqlite3_clear_bindings(pStatement_);
    
    Rcpp::CharacterVector names = params.attr("names");
    for (int i = 0; i < params.size(); ++i) {
      bind_parameter(pStatement_, i, std::string(names[i]), params[i]);
    }
    
    init();
  }
  
  bool complete() {
    return complete_;
  }
  
  int nrows() {
    return nrows_;
  }
  
  int rows_affected() {
    return rows_affected_;
  }

  void step() {
    nrows_++;
    int rc = sqlite3_step(pStatement_);
    
    if (rc == SQLITE_DONE) {
      complete_ = true;
    } else if (rc != SQLITE_ROW) {
      Rcpp::stop(pConn_->getException());
    }
  }
  
  // We try to determine the correct R type for each column in the
  // result. Currently only the first row is used to guess the type.
  // If a NULL value appears in the first row of the result and the column 
  // corresponds to a DB table column, we guess the type based on the schema
  // Otherwise, we default to character.
  std::vector<SEXPTYPE> cache_field_data() {
    types_.clear();
    names_.clear();
    
    int p = ncols_;
    for (int j = 0; j < p; ++j) {
      names_.push_back(sqlite3_column_name(pStatement_, j));
      
      switch(sqlite3_column_type(pStatement_, j)) {
      case SQLITE_INTEGER:
        types_.push_back(INTSXP);
        break;
      case SQLITE_FLOAT:
        types_.push_back(REALSXP);
        break;
      case SQLITE_TEXT:
        types_.push_back(STRSXP);
        break;
      case SQLITE_BLOB:
        // List of raw vectors
        types_.push_back(VECSXP);
        break;
      default: // SQLITE_NULL
        const char* decl_raw = sqlite3_column_decltype(pStatement_, j);
        if (decl_raw == NULL) {
          types_.push_back(STRSXP);
        } else {
          std::string decl(decl_raw);
          if (decl == "INTEGER") {
            types_.push_back(INTSXP);
          } else if (decl == "REAL") {
            types_.push_back(REALSXP);
          } else if (decl == "BLOB") {
            types_.push_back(VECSXP);
          } else {
            types_.push_back(STRSXP);
          }
        }
      }
    }
    return types_;
  }
  
  
  Rcpp::List fetch(int n_max = 10) {
    if (!ready_)
      Rcpp::stop("Prepared query needs to be bound first");

    if (complete_) 
      n_max = 0;

    Rcpp::List out = df_create(types_, n_max);

    int i;
    for (i = 0; i < n_max && !complete_; ++i) {
      for (int j = 0; j < ncols_; ++j) {
        set_col_value(out[j], types_[j], pStatement_, i, j);  
      }
      step();
    }
    
    // If there weren't enough rows to fill up the initial set, trim them back
    if (i < n_max) {
      out = df_resize(out, i);
    }
    
    out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -i);
    out.attr("class") = "data.frame";
    out.attr("names") = names_;

    return out;
  }
  

  Rcpp::List fetch_all() {
    if (!ready_)
      Rcpp::stop("Prepared query needs to be bound first");
    
    int n = 100;
    Rcpp::List out = df_create(types_, n);
    
    int i = 0;
    while(!complete_) {
      if (i >= n) {
        n *= 2;
        out = df_resize(out, n);
      }
      
      for (int j = 0; j < ncols_; ++j) {
        set_col_value(out[j], types_[j], pStatement_, i, j);  
      }
      
      step();
      ++i;
    }

    // Trim back to what we actually used
    if (i < n) {
      out = df_resize(out, i);
    }
    
    out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -i);
    out.attr("class") = "data.frame";
    out.attr("names") = names_;
    
    return out;
  }
  
  Rcpp::List column_info() {
    Rcpp::CharacterVector names(ncols_);
    for (int i = 0; i < ncols_; i++) {
      names[i] = names_[i]; 
    }
    
    Rcpp::CharacterVector types(ncols_);
    for (int i = 0; i < ncols_; i++) {
      switch(types_[i]) {
      case STRSXP:  types[i] = "character"; break;
      case INTSXP:  types[i] = "integer"; break;
      case REALSXP: types[i] = "double"; break;
      case VECSXP:  types[i] = "list"; break;
      default: Rcpp::stop("Unknown variable type");
      }
    }
    
    Rcpp::List out = Rcpp::List::create(names, types);
    out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -ncols_);
    out.attr("class") = "data.frame";
    out.attr("names") = Rcpp::CharacterVector::create("name", "type");
    
    return out;
  }
  
  virtual ~SqliteResult() {
    try {
      sqlite3_finalize(pStatement_); 
    } catch(...) {}
  }
};


