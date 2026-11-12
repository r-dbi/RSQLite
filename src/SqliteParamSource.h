#ifndef RSQLITE_SQLITEPARAMSOURCE_H
#define RSQLITE_SQLITEPARAMSOURCE_H

#include <cpp11.hpp>
#include <boost/noncopyable.hpp>
#include <vector>
#include "sqlite3-cpp.h"
#include "DbArrow.h"

// The parameter sets bound to a prepared statement, one at a time:
// the statement runs once for each set.
// A source must not leave by the longjmp of an R error,
// which skips the C++ frames of the result:
// the result would stay ready on a statement
// that was reset and only partly bound,
// and the next fetch would step it with the bindings cleared.
// R API calls that can fail go through cpp11's safe wrappers,
// whose exception the result handles like any other error,
// or are made before binding starts.
// SqliteListParamSource reads its vectors with R's API directly,
// as the result did before: that fails only for an ALTREP vector
// whose data pointer can't be taken.
class SqliteParamSource : public boost::noncopyable {
public:
  virtual ~SqliteParamSource();

public:
  // Resets the statement and binds the next set to it, and returns true,
  // or returns false once all sets are bound.
  // A value that can't be bound throws a std::runtime_error,
  // which the result raises as an error of the statement.
  virtual bool bind_next_row(sqlite3_stmt* stmt) = 0;
};

// Parameters given as a list of R vectors of equal length,
// one vector per placeholder and one element per set.
// The list protects the vectors for as long as the source lives,
// across the fetches that bind the later sets.
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

// Parameters given as an Arrow array stream of struct arrays,
// one set per row:
// placeholder k + 1 takes the values of the child `indexes[k]`.
// The constructor checks the schema and only then takes the stream over,
// so that a stream of a type that can't be bound stays with its owner;
// the source releases it when it is destroyed.
// The arrays are read as the sets are bound.
// The stream's callbacks may call R:
// an R error that leaves them by a longjmp becomes a C++ exception.
class SqliteArrowParamSource : public SqliteParamSource {
  nanoarrow::UniqueArrayStream stream;
  nanoarrow::UniqueSchema schema;
  // The types of the children that `indexes` names, in the same order
  std::vector<struct ArrowSchemaView> types;
  std::vector<int> indexes;
  nanoarrow::UniqueArray array;
  nanoarrow::UniqueArrayView view;
  int64_t i;

public:
  SqliteArrowParamSource(
    struct ArrowArrayStream* stream_,
    const std::vector<int>& indexes_
  );

public:
  virtual bool bind_next_row(sqlite3_stmt* stmt);

private:
  bool next_array();
  void bind_parameter(sqlite3_stmt* stmt, int pos, int64_t row) const;
};

#endif  // RSQLITE_SQLITEPARAMSOURCE_H
