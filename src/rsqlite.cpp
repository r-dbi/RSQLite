#define STRICT_R_HEADERS
#define R_NO_REMAP
#include <cpp11/R.hpp>

#include "pch.h"
#include "sqlite3.h"

//' RSQLite version
//'
//' @return A character vector containing header and library versions of
//'   RSQLite.
//' @export
//' @examples
//' RSQLite::rsqliteVersion()
[[cpp11::register]]
CharacterVector rsqliteVersion() {
  return
    CharacterVector::create(
      _["header"] = SQLITE_VERSION,
      _["library"] = sqlite3_libversion()
    );
}

[[cpp11::register]]
void init_logging(const std::string& log_level) {
  plog::init_r(log_level);
}
