#ifndef __RSQLSITE_SQLITE_UTILS__
#define __RSQLSITE_SQLITE_UTILS__

#include <RSQLite.h>
#include "sqlite3/sqlite3.h"


Rcpp::List inline dfResize(const Rcpp::List& df, const int n) {
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

#endif // __RSQLSITE_SQLITE_UTILS__
