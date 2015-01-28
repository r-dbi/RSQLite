#include <Rcpp.h>
#include "sqlite3.h"

class SqliteResult;

// Connection ------------------------------------------------------------------

class SqliteConnection {
  friend class SqliteResult;
  sqlite3* pConn_;

public:
    SqliteConnection(std::string path, bool allow_ext, int flags, std::string vfs = "") {
    int rc = sqlite3_open_v2(path.c_str(), &pConn_, flags, vfs.size() ? vfs.c_str() : NULL);
    if (rc != SQLITE_OK) {
      Rcpp::stop("Could not connect to database:\n%s", getException());
    }
    if (allow_ext) {
      sqlite3_enable_load_extension(pConn_, 1);
    }
  }
  
  virtual ~SqliteConnection() {
    try {
      sqlite3_close_v2(pConn_); 
    } catch(...) {}
  }

  std::string getException() const {
    return std::string(sqlite3_errmsg(pConn_));
  }
    
// Prevent copying because of shared resource
private:
  SqliteConnection( SqliteConnection const& );
  SqliteConnection operator=( SqliteConnection const& );
  
};

// Result ----------------------------------------------------------------------

class SqliteResult {
  sqlite3_stmt* pStatement_;
  bool complete_;
  int nrows_;
  std::vector<SEXPTYPE> types_;
  
public:
  SqliteResult(SqliteConnection* con, std::string sql) {
    int rc = sqlite3_prepare_v2(con->pConn_, sql.c_str(), sql.size() + 1, 
      &pStatement_, NULL);
    
    if (rc != SQLITE_OK) {
      Rcpp::stop("Could not send query:\n%s", con->getException());
    }
    
    nrows_ = 0;
    complete_ = false;
  }
  
  void step() {
    nrows_++;
    int rc = sqlite3_step(pStatement_);
    
    if (rc == SQLITE_DONE) {
      complete_ = true;
    } else if (rc != SQLITE_ROW) {
      Rcpp::stop("Could not fetch row");
    }
  }
  
  // We try to determine the correct R type for each column in the
  // result. Currently only the first row is used to guess the type.
  // If a NULL value appears in the first row of the result and the column 
  // corresponds to a DB table column, we guess the type based on the schema
  // Otherwise, we default to character.
  std::vector<SEXPTYPE> column_info() {
    if (types_.size() != 0) return types_;
    
    int p = ncol();
    for (int j = 0; j < p; ++j) {
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
        // Needs to be list of raw?
        types_.push_back(RAWSXP);
        break;
      default: // SQLITE_NULL
        std::string decl(sqlite3_column_decltype(pStatement_, j));
        if (decl == "INTEGER") {
          types_.push_back(INTSXP);
        } else if (decl == "DOUBLE") {
          types_.push_back(REALSXP);
        } else if (decl == "RAW") {
          types_.push_back(RAWSXP);
        } else {
          types_.push_back(STRSXP);
        }
      }
    }
    return types_;
  }
  
  
  Rcpp::List fetch(int n_max = 10) {
    step();
    if (!complete_) Rcpp::stop("No rows to fetch");

    int p = ncol();
    std::vector<SEXPTYPE> types = column_info();

    // Space for output
    Rcpp::List out(p);
    for (int j = 0; j < p; ++j) {
      out[j] = Rf_allocVector(types[j], n_max);
    }
    
    for (int i = 0; i < n_max && !complete_; ++i) {
      for (int j = 0; j < p; ++j) {
        SEXP col = out[j];
        
        switch(types[j]) {
        case INTSXP:
          INTEGER(col)[i] = sqlite3_column_int(pStatement_, j);
          break;
        case REALSXP:
          REAL(col)[i] = sqlite3_column_double(pStatement_, j);
          break;
        case STRSXP:
          SET_STRING_ELT(col, i, Rf_mkCharCE((const char*) sqlite3_column_text(pStatement_, j), CE_UTF8));
          break;
        case RAWSXP:
          // Something with memcpy & RAW?
          break;
        }
      }      
      step();
    }
    
    return out;
  }
  
  
  int ncol() const {
    return sqlite3_column_count(pStatement_);
  }
  
  virtual ~SqliteResult() {
    try {
      sqlite3_finalize(pStatement_); 
    } catch(...) {}
  }
  
  // Prevent copying because of shared resource
private:
  SqliteResult( SqliteResult const& );
  SqliteResult operator=( SqliteResult const& );
  
};


