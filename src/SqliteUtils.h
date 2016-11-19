#ifndef __RSQLSITE_SQLITE_UTILS__
#define __RSQLSITE_SQLITE_UTILS__

#include <RSQLite.h>
#include "sqlite3.h"


List inline dfResize(const List& df, const int n) {
  int p = df.size();

  List out(p);
  for (int j = 0; j < p; ++j) {
    out[j] = Rf_lengthgets(df[j], n);
  }

  out.names() = df.names();
  out.attr("class") = df.attr("class");
  out.attr("row.names") = IntegerVector::create(NA_INTEGER, -n);

  return out;
}

List inline dfCreate(std::vector<std::string> names, int n) {
  int p = names.size();

  List out(p);
  out.attr("names") = names;
  out.attr("class") = "data.frame";
  out.attr("row.names") = IntegerVector::create(NA_INTEGER, -n);

  return out;
}

#endif // __RSQLSITE_SQLITE_UTILS__
