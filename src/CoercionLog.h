#ifndef RSQLITE_COERCIONLOG_H
#define RSQLITE_COERCIONLOG_H

#include <cpp11.hpp>
#include <stdint.h>
#include <vector>

// What happened to a value that didn't fit the Arrow type of its column,
// see SqliteArrowColumn::append_value()
enum COERCION_REASON {
  // Converted as SQLite converts it
  CR_CONVERTED,
  // NULL: beyond the range of the type
  CR_OUT_OF_RANGE,
  // NULL: text or a blob in a utf8 column that isn't valid UTF-8
  // or holds a NUL byte
  CR_INVALID_UTF8,
  // NULL: text that can't be parsed, or a blob, in a date or time column
  CR_UNPARSABLE,
  // NULL: a value in a column of the null type
  CR_NULL_TYPE
};

// The values of one column of a chunk that didn't fit its type,
// grouped by storage class and reason, with their count
// and the first of their 1-based row numbers in the result,
// in the order of their first rows.
// Recording calls no R API: the log is handed to R with as_list()
// once the chunk is complete.
class CoercionLog {
public:
  // The row numbers kept for each group
  static const size_t N_ROWS = 5;

  void record(int column_type, COERCION_REASON reason, int64_t row);
  // Moves the values of `column_type` logged with `from` to `to`
  void merge(int column_type, COERCION_REASON from, COERCION_REASON to);
  bool empty() const;
  void clear();

  // One R list per group, with its storage class, reason, count,
  // and rows: the first N_ROWS row numbers, as doubles
  cpp11::writable::list as_list() const;

private:
  struct Entry {
    int column_type;
    COERCION_REASON reason;
    int64_t count;
    std::vector<int64_t> rows;
  };
  std::vector<Entry> entries;

  Entry* find(int column_type, COERCION_REASON reason);
};

#endif  // RSQLITE_COERCIONLOG_H
