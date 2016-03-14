#ifndef __RSQLSITE_SQLITE_RESULT__
#define __RSQLSITE_SQLITE_RESULT__

#include <Rcpp.h>
#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include "sqlite3/sqlite3.h"

#include "SqliteConnection.h"
#include "SqliteUtils.h"

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
      try {
        init(); 
      } catch(...) {
        sqlite3_finalize(pStatement_);
        throw;
      }
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
  
  void bind_rows(Rcpp::List params) {
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
  
  static SEXPTYPE datatype_to_sexptype(const int field_type) {
    switch(field_type) {
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
  
  static SEXPTYPE decltype_to_sexptype(const char* decl_type) {
    if (decl_type == NULL)
      return STRSXP;
    
    if (std::string("INTEGER") == decl_type)
      return INTSXP;
    if (std::string("REAL") == decl_type)
      return REALSXP;
    if (std::string("BLOB") == decl_type)
      return VECSXP;

    return STRSXP;
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
      
      SEXPTYPE type = datatype_to_sexptype(sqlite3_column_type(pStatement_, j));
      if (type == NILSXP)
        type = decltype_to_sexptype(sqlite3_column_decltype(pStatement_, j));
      
      types_.push_back(type);
    }
    return types_;
  }
  
  void set_raw_value(SEXP col, const int i, const int j) {
    int size = sqlite3_column_bytes(pStatement_, j);
    const void* blob = sqlite3_column_blob(pStatement_, j);
    
    SEXP bytes = Rf_allocVector(RAWSXP, size);
    memcpy(RAW(bytes), blob, size);
    
    SET_VECTOR_ELT(col, i, bytes);
  }
  
  void set_col_value(SEXP col, const int i, const int j) {
    SEXPTYPE type = types_[j];
    
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
    case VECSXP:
      set_raw_value(col, i, j);
      break;
    }
  }
  
  Rcpp::List fetch(int n_max = -1) {
    if (!ready_)
      Rcpp::stop("Query needs to be bound before fetching");

    int n = (n_max < 0) ? 100 : n_max;
    Rcpp::List out = dfCreate(types_, names_, n);
    
    int i = 0;
    while(!complete_) {
      if (i >= n) {
        if (n_max < 0) {
          n *= 2;
          out = dfResize(out, n);
        } else {
          break;
        }
      }
      
      for (int j = 0; j < ncols_; ++j) {
        set_col_value(out[j], i, j);
      }
      step();
      ++i;
      
      if (i % 1000 == 0)
        Rcpp::checkUserInterrupt();
    }
    
    // Trim back to what we actually used
    if (i < n) {
      out = dfResize(out, i);
    }
    
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

#endif // __RSQLSITE_SQLITE_RESULT__
