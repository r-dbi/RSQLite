#ifndef RSQLITE_SQLITEARROWCOLUMN_H
#define RSQLITE_SQLITEARROWCOLUMN_H

#include <string>

#include "sqlite3-cpp.h"
#include "CoercionLog.h"
#include "DbArrow.h"
#include "SqliteColumnDataSource.h"

// The Arrow type of a result column.
//
// SQLite is dynamically typed, so the type is decided from the first value
// seen (int64, double, utf8 or binary), or from the declared type of the
// column: the date and time types when `extended_types` is set, otherwise the
// affinity, which only matters when every value of the first chunk is NULL.
// Columns without a declared type that never see a value are of the null type.
// A type requested up front, see ArrowTarget, skips the decision.
enum ARROW_KIND {
  AK_UNDECIDED,
  AK_NA,
  AK_BOOL,
  AK_INT8,
  AK_INT16,
  AK_INT32,
  AK_INT64,
  AK_UINT8,
  AK_UINT16,
  AK_UINT32,
  AK_UINT64,
  AK_FLOAT,
  AK_DOUBLE,
  AK_STRING,
  AK_LARGE_STRING,
  AK_BINARY,
  AK_LARGE_BINARY,
  AK_DATE32,
  AK_DATE64,
  AK_TIME32,
  AK_TIME64,
  AK_TIMESTAMP
};

// An Arrow type requested for a column: the kind, and for the time types the
// unit and the time zone
struct ArrowTarget {
  bool set;
  ARROW_KIND kind;
  enum ArrowTimeUnit unit;
  std::string timezone;

  ArrowTarget()
      : set(false), kind(AK_UNDECIDED), unit(NANOARROW_TIME_UNIT_MICRO) {}

  // Reads the target from a schema, throws for a type that can't be filled
  static ArrowTarget from_schema(
    const struct ArrowSchema* schema,
    const std::string& name
  );
};

class SqliteArrowColumn {
  sqlite3_stmt* stmt;
  const int j;
  const std::string name;
  const bool with_alt_types;
  SqliteColumnDataSource source;

  ARROW_KIND kind;
  enum ArrowTimeUnit unit;
  std::string timezone;
  // Set when the schema has been handed out or the type was requested:
  // the kind is final from then on
  bool frozen;

  // Child array of the chunk under construction
  nanoarrow::UniqueArray array;
  // Rows of the current chunk seen while undecided (all NULL)
  int64_t pending_nulls;
  // Values of the current chunk that were not of the column's type
  CoercionLog log;

public:
  SqliteArrowColumn(
    sqlite3_stmt* stmt_,
    const int j_,
    const std::string& name_,
    bool with_alt_types_,
    const ArrowTarget& target
  );

public:
  bool decided() const;
  bool is_frozen() const;
  // Decides the kind from the value of the current row, if there is one
  void decide_from_row(bool has_row);
  // Decides the kind from the declared type, falling back to the null type
  void decide_from_decltype();
  void freeze();

  void set_schema(struct ArrowSchema* schema) const;

  // Chunk building, `row` is the 1-based row number in the result
  void start_chunk();
  void append_row(int64_t row);
  void finish_chunk(int64_t n);
  void move_chunk_to(struct ArrowArray* out);
  int64_t variable_bytes();

  // The values of the chunk that were not of the column's type, as an R list
  // with the column name, the type and the entries of the log, which is
  // cleared; NULL if there were none
  cpp11::sexp coercions();

private:
  static ARROW_KIND kind_from_column_type(int column_type);
  ARROW_KIND kind_from_decltype() const;

  void init_array();
  void append_value(int column_type, int64_t row);
  void append_integer(int column_type, int64_t row);
  void append_string(int column_type, int64_t row);
  void append_binary(int column_type, int64_t row);
  void append_date(int column_type, int64_t row);
  void append_time(int column_type, int64_t row);
  void append_null();
  bool in_range(int64_t value) const;
  void promote_to_double();
  static const char* format_kind(ARROW_KIND kind);
};

#endif  // RSQLITE_SQLITEARROWCOLUMN_H
