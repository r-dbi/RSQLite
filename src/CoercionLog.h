#ifndef RSQLITE_COERCIONLOG_H
#define RSQLITE_COERCIONLOG_H

#include <cpp11.hpp>
#include <stdint.h>
#include <vector>

// What happened to a value that was not of the type of its column
enum COERCION_REASON {
  // Converted by SQLite's own rules
  CR_CONVERTED,
  // A blob that is not valid UTF-8 text, NULL instead
  CR_INVALID_UTF8,
  // A date or time that could not be parsed, NULL instead
  CR_UNPARSABLE,
  // A number outside the range of the type, NULL instead
  CR_OUT_OF_RANGE
};

// The values of one column that were not of its type, grouped by storage
// class and reason, with their 1-based row numbers in the result.
// Only the first rows and the last two are kept, enough for a truncated list.
class CoercionLog {
public:
  static const size_t N_HEAD = 20;

  struct Entry {
    int column_type;
    COERCION_REASON reason;
    int64_t count;
    std::vector<int64_t> head;
    int64_t last[2];
  };

public:
  void record(int column_type, COERCION_REASON reason, int64_t row);
  bool empty() const;
  void clear();

  // One R list per entry, with the fields class, reason, count, rows (the
  // first rows) and last (the last two rows, NULL unless rows were left out)
  cpp11::writable::list as_list() const;

  static const char* format_column_type(int column_type);
  static const char* format_reason(COERCION_REASON reason);

private:
  std::vector<Entry> entries;
};

#endif  // RSQLITE_COERCIONLOG_H
