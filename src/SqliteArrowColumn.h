#ifndef RSQLITE_SQLITEARROWCOLUMN_H
#define RSQLITE_SQLITEARROWCOLUMN_H

#include <string>

#include "sqlite3-cpp.h"
#include "DbArrow.h"

// The Arrow type of a result column.
//
// SQLite is dynamically typed, so the type is decided from the first value
// that is not NULL: int64 for an integer, double for a real.
// An int64 column widens to double when a real arrives later in the same chunk.
// A column whose values in that chunk are all NULL takes the type of its
// declared affinity: int64 for INTEGER, double for REAL and NUMERIC,
// and the null type without a declared type, as for an expression.
//
// The first chunk of an execution fixes the types for its later chunks.
// There, a real in an int64 column is truncated toward zero,
// or NULL beyond the range of int64,
// and a value in a column of the null type is NULL.
//
// Text and blobs are not supported yet: a value of either fails the fetch,
// as does a column of NULL values whose declared affinity is TEXT or BLOB.
enum ARROW_KIND { AK_UNDECIDED, AK_NA, AK_INT64, AK_DOUBLE };

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

public:
  SqliteArrowColumn(
    sqlite3_stmt* stmt_,
    const int j_,
    const std::string& name_
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
  void append_null();
  void promote_to_double();
  NORET void stop_unsupported() const;
};

#endif  // RSQLITE_SQLITEARROWCOLUMN_H
