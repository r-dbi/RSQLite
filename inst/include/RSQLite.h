#include <Rcpp.h>
#include "sqlite3.h"

class SqliteResult;

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
  std::vector<std::string> names_;
  
public:
  SqliteResult(SqliteConnection* con, std::string sql) {
    int rc = sqlite3_prepare_v2(con->pConn_, sql.c_str(), sql.size() + 1, 
      &pStatement_, NULL);
    
    if (rc != SQLITE_OK) {
      Rcpp::stop("Could not send query:\n%s", con->getException());
    }
    
    nrows_ = 0;
    complete_ = false;
    
    step();
    cache_field_data();
  }
  
  bool complete() {
    return complete_;
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
  std::vector<SEXPTYPE> cache_field_data() {
    int p = ncol();
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
        std::string decl(sqlite3_column_decltype(pStatement_, j));
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
    return types_;
  }
  
  
  Rcpp::List fetch(int n_max = 10) {
    int p = ncol();
    if (complete_) 
      n_max = 0;

    Rcpp::List out = df_create(types_, n_max);

    int i;
    for (i = 0; i < n_max && !complete_; ++i) {
      for (int j = 0; j < p; ++j) {
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


