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
        Rcpp::stop("Parameter %i does not have length 1.", j);
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
        set_col_value(out[j], types_[j], pStatement_, i, j);  
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
