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

// For tests that need SQLite to run out of memory.
// Sets the hard and then the soft heap limit, leaving a limit alone for -1,
// and returns the earlier limits.
// PRAGMA hard_heap_limit cannot lift a limit, and lowering the hard limit
// also lowers the soft limit, which must be restored separately.
[[cpp11::register]]
cpp11::doubles sqlite_heap_limits(double hard, double soft) {
  using namespace cpp11::literals;
  const sqlite3_int64 prior_hard = sqlite3_hard_heap_limit64(-1);
  const sqlite3_int64 prior_soft = sqlite3_soft_heap_limit64(-1);
  sqlite3_hard_heap_limit64(static_cast<sqlite3_int64>(hard));
  sqlite3_soft_heap_limit64(static_cast<sqlite3_int64>(soft));
  return cpp11::doubles(
    { "hard"_nm = static_cast<double>(prior_hard),
      "soft"_nm = static_cast<double>(prior_soft) }
  );
}

[[cpp11::register]]
double sqlite_memory_used() {
  return static_cast<double>(sqlite3_memory_used());
}
