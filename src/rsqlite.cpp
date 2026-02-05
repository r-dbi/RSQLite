#include <cpp11/R.hpp>

#include "pch.h"
#include "sqlite3-cpp.h"

[[cpp11::register]]
cpp11::strings rsqliteVersion() {
  using namespace cpp11::literals;
  return cpp11::strings(
    { "header"_nm = SQLITE_VERSION, "library"_nm = sqlite3_libversion() }
  );
}
