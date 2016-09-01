#ifndef __RSQLSITE_SQLITE_UTILS__
#define __RSQLSITE_SQLITE_UTILS__

#include <Rcpp.h>
#include "sqlite3/sqlite3.h"


Rcpp::List inline dfResize(Rcpp::List df, int n) {
  int p = df.size();
  
  Rcpp::List out(p);
  for (int j = 0; j < p; ++j) {
    out[j] = Rf_lengthgets(df[j], n);
  }
  
  out.attr("names") = df.attr("names");
  out.attr("class") = df.attr("class");
  out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -n);
  
  return out;
}

Rcpp::List inline dfCreate(std::vector<std::string> names, int n) {
  int p = names.size();
  
  Rcpp::List out(p);
  out.attr("names") = names;
  out.attr("class") = "data.frame";
  out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -n);
  
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

void inline bind_parameter(sqlite3_stmt* stmt, int i, int j, std::string name, SEXP value_) {
  if (name != "") {
    j = find_parameter(stmt, name);
    if (j == 0)
      Rcpp::stop("No parameter with name %s.", name);
  } else {
    j++; // sqlite parameters are 1-indexed
  }
  
  // std::cerr << "TYPEOF(value_): " << TYPEOF(value_) << "\n";

  if (TYPEOF(value_) == LGLSXP) {
    Rcpp::LogicalVector value(value_);
    if (value[i] == NA_LOGICAL) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_int(stmt, j, value[i]);
    }
  } else if (TYPEOF(value_) == INTSXP) {
    Rcpp::IntegerVector value(value_);
    if (value[i] == NA_INTEGER) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_int(stmt, j, value[i]);
    }
  } else if (TYPEOF(value_) == REALSXP) {
    Rcpp::NumericVector value(value_);
    if (value[i] == NA_REAL) {
      sqlite3_bind_null(stmt, j);
    } else {
      sqlite3_bind_double(stmt, j, value[i]);
    }
  } else if (TYPEOF(value_) == STRSXP) {
    Rcpp::CharacterVector value(value_);
    if (value[i] == NA_STRING) {
      sqlite3_bind_null(stmt, j);
    } else {
      Rcpp::String value2 = value[i];
      std::string value3(value2);
      sqlite3_bind_text(stmt, j, value3.data(), value3.size(), 
        SQLITE_TRANSIENT);
    }
  } else if (TYPEOF(value_) == VECSXP) {
    SEXP raw = VECTOR_ELT(value_, i); 
    if (TYPEOF(raw) != RAWSXP) {
      Rcpp::stop("Can only bind lists of raw vectors");
    }
    
    sqlite3_bind_blob(stmt, j, RAW(raw), Rf_length(raw), SQLITE_TRANSIENT);
  } else {
    Rcpp::stop("Don't know how to handle parameter of type %s.", 
      Rf_type2char(TYPEOF(value_)));
  }
}

#endif // __RSQLSITE_SQLITE_UTILS__
