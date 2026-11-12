#ifndef RSQLITE_SQLITEARROWCOLUMN_H
#define RSQLITE_SQLITEARROWCOLUMN_H

#include <string>
#include <utility>
#include <vector>

#include "sqlite3-cpp.h"
#include "DbArrow.h"

// The Arrow type of a result column.
//
// With `extended_types`, a column declared as DATE, TIME, DATETIME or TIMESTAMP
// is date32, time64[us] or timestamp[us, UTC] whatever its values,
// as the data frame path reads it as Date, hms or POSIXct in UTC.
// Otherwise SQLite is dynamically typed, so the type is decided from the first
// value that is not NULL: int64 for an integer, double for a real,
// utf8 for text, binary for a blob.
// An int64 column widens to double when a real arrives later in the same chunk.
// A column whose values in that chunk are all NULL takes the type of its
// declared affinity: int64 for INTEGER, double for REAL and NUMERIC,
// utf8 for TEXT, binary for BLOB,
// and the null type without a declared type, as for an expression.
//
// The first chunk of an execution fixes the types for its later chunks.
// Values that don't fit the type of their column are converted or NULL,
// see append_value(), and not reported yet.
enum ARROW_KIND {
  AK_UNDECIDED,
  AK_NA,
  AK_INT64,
  AK_DOUBLE,
  AK_STRING,
  AK_BINARY,
  AK_DATE32,
  AK_TIME64,
  AK_TIMESTAMP
};

class SqliteArrowColumn {
  sqlite3_stmt* stmt;
  const int j;
  const std::string name;

  ARROW_KIND kind;
  // Set once the first chunk is complete: the kind is final from then on
  bool frozen;

  // Child array of the chunk under construction
  nanoarrow::UniqueArray array;
  // Rows of the current chunk seen while undecided (all NULL)
  int64_t pending_nulls;
  // Rows of the current chunk whose text or blob an open int64 column has
  // read as an integer, with their reading as a real for promote_to_double()
  std::vector<std::pair<int64_t, double> > text_reals;

public:
  // With `with_alt_types`, the column takes the date and time types
  // from its declared type
  SqliteArrowColumn(
    sqlite3_stmt* stmt_,
    const int j_,
    const std::string& name_,
    bool with_alt_types
  );

public:
  bool decided() const;
  // Decides the kind from the declared type, falling back to the null type
  void decide_from_decltype();
  void freeze();

  void set_schema(struct ArrowSchema* schema) const;

  // Chunk building
  void start_chunk();
  // Appends the value of the current row
  void append_row();
  // Completes the chunk of `n` rows:
  // a column that has seen only NULL takes its declared type
  void finish_chunk(int64_t n);
  void move_chunk_to(struct ArrowArray* out);

private:
  static ARROW_KIND kind_from_column_type(int column_type);
  ARROW_KIND kind_from_decltype() const;

  void init_array();
  void append_value(int column_type);
  void append_int64(int column_type);
  bool integer_value(int column_type, int64_t& value) const;
  void append_string(int column_type);
  struct ArrowBufferView value_bytes(int column_type) const;
  const char* value_text() const;
  double text_real() const;
  void append_date(int column_type);
  void append_time(int column_type);
  void append_null();
  void promote_to_double();
  NORET void stop_out_of_memory() const;
};

#endif  // RSQLITE_SQLITEARROWCOLUMN_H
