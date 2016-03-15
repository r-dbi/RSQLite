#ifndef __RSQLSITE_SQLITE_UTILS__
#define __RSQLSITE_SQLITE_UTILS__

#include <Rcpp.h>
#include "sqlite3/sqlite3.h"

void inline set_raw_value(SEXP col, sqlite3_stmt* pStatement_, int i, int j) {
  int size = sqlite3_column_bytes(pStatement_, j);
  const void* blob = sqlite3_column_blob(pStatement_, j);
  
  SEXP bytes = Rf_allocVector(RAWSXP, size);
  memcpy(RAW(bytes), blob, size);

  SET_VECTOR_ELT(col, i, bytes);
}

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
  case VECSXP:
    set_raw_value(col, pStatement_, i, j);
    // Something with memcpy & RAW?
    break;
  }
}


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

Rcpp::List inline dfCreate(std::vector<SEXPTYPE> types, std::vector<std::string> names, int n) {
  int p = types.size();
  
  Rcpp::List out(p);
  out.attr("names") = names;
  out.attr("class") = "data.frame";
  out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -n);
  
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

void inline bind_parameter(sqlite3_stmt* stmt, int i, int j, std::string name, SEXP value_) {
  if (name != "") {
    j = find_parameter(stmt, name);
    if (j == 0)
      Rcpp::stop("No parameter with name %s.", name);
  } else {
    j++; // sqlite parameters are 1-indexed
  }

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
