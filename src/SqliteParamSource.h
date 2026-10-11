#ifndef RSQLITE_SQLITEPARAMSOURCE_H
#define RSQLITE_SQLITEPARAMSOURCE_H

#include <vector>

#include "sqlite3-cpp.h"
#include "DbArrow.h"

// The rows of parameters bound to a prepared statement, one row at a time.
// Each row is bound after resetting the statement, and the statement is
// executed once per row.
class SqliteParamSource {
public:
  virtual ~SqliteParamSource();

public:
  // Binds the next row and returns true, or returns false once all rows are
  // bound.
  virtual bool bind_next_row(sqlite3_stmt* stmt) = 0;
};

// Parameters given as a list of R vectors of equal length
class SqliteListParamSource : public SqliteParamSource {
  cpp11::list params;
  R_xlen_t i, n;

public:
  SqliteListParamSource(const cpp11::list& params_);

public:
  virtual bool bind_next_row(sqlite3_stmt* stmt);

private:
  void bind_parameter(sqlite3_stmt* stmt, int pos, SEXP value_) const;
};

// Parameters given as an Arrow stream of struct arrays, one child per
// placeholder; `param_indexes` maps each placeholder to a child.
// Batches are read from the stream as needed.
class SqliteArrowParamSource : public SqliteParamSource {
  nanoarrow::UniqueArrayStream stream;
  nanoarrow::UniqueSchema schema;
  std::vector<struct ArrowSchemaView> schema_views;
  std::vector<struct ArrowSchemaView> dictionary_views;
  nanoarrow::UniqueArray array;
  nanoarrow::UniqueArrayView view;
  std::vector<int> param_indexes;
  int64_t i, n;
  bool exhausted;

public:
  SqliteArrowParamSource(
    struct ArrowArrayStream* stream_,
    const std::vector<int>& param_indexes_
  );

public:
  virtual bool bind_next_row(sqlite3_stmt* stmt);

private:
  bool next_batch();
  void bind_parameter(sqlite3_stmt* stmt, int pos, int child, int64_t row);
  void bind_string(
    sqlite3_stmt* stmt,
    int pos,
    const struct ArrowArrayView* values,
    int64_t row
  );
  static double units_per_second(enum ArrowTimeUnit unit);
};

#endif  // RSQLITE_SQLITEPARAMSOURCE_H
