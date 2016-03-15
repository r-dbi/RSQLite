#include <Rcpp.h>
#include "sqlite3/sqlite3.h"
using namespace Rcpp;

//' RSQLite version
//' 
//' @return A character vector containing header and library versions of 
//'   RSQLite.
//' @export
// [[Rcpp::export]]
CharacterVector rsqliteVersion() {
  return CharacterVector::create(
    _["header"] = SQLITE_VERSION,
    _["library"] = sqlite3_libversion()
  );
}
