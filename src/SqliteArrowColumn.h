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
enum ARROW_KIND {
  AK_UNDECIDED,
  AK_NA,
  AK_INT64,
  AK_DOUBLE,
  AK_STRING,
  AK_BINARY,
  AK_DATE,
  AK_TIME,
  AK_TIMESTAMP
};

class SqliteArrowColumn {
  sqlite3_stmt* stmt;
  const int j;
  const std::string name;
  const bool with_alt_types;
  SqliteColumnDataSource source;

  ARROW_KIND kind;
  // Set when the schema has been handed out: the kind is final from then on
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
    bool with_alt_types_
  );

public:
  bool decided() const;
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
  void append_null();
  void promote_to_double();
  static const char* format_kind(ARROW_KIND kind);
};

#endif  // RSQLITE_SQLITEARROWCOLUMN_H
