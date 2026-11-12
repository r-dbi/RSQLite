#ifndef RSQLITE_SQLITEPARAMSOURCE_H
#define RSQLITE_SQLITEPARAMSOURCE_H

#include <cpp11.hpp>
#include <boost/noncopyable.hpp>
#include "sqlite3-cpp.h"

// The parameter sets bound to a prepared statement, one at a time:
// the statement runs once for each set.
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

#endif  // RSQLITE_SQLITEPARAMSOURCE_H
