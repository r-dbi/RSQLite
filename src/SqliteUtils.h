#ifndef __RSQLSITE_SQLITE_UTILS__
#define __RSQLSITE_SQLITE_UTILS__

#include <Rcpp.h>
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

#endif // __RSQLSITE_SQLITE_UTILS__
