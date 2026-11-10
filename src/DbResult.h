#ifndef __RDBI_DB_RESULT__
#define __RDBI_DB_RESULT__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/scoped_ptr.hpp>
#include <vector>

#include "DbResultImplDecl.h"

class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;

class DbResult;
typedef boost::shared_ptr<DbResult> DbResultPtr;

struct ArrowSchema;
struct ArrowArray;
struct ArrowArrayStream;
struct ArrowDfColumns;

// DbResult --------------------------------------------------------------------

class DbResult : boost::noncopyable {
  DbConnectionPtr pConn_;
  // Set while a fetch or a bind runs, see DbResult.cpp
  bool busy_;

protected:
  boost::scoped_ptr<DbResultImpl> impl;

protected:
  DbResult(const DbConnectionPtr& pConn);

public:
  ~DbResult();

public:
  void close();

  bool complete() const;
  bool ready() const;
  bool is_active() const;
  bool busy() const;
  // Counts the executions of the statement with new parameters:
  // bind() and bind_arrow() start a new one
  int64_t executions() const;
  int n_rows_fetched();
  int n_rows_affected();

  void bind(const cpp11::list& params);
  cpp11::list fetch(int n_max = -1);

  cpp11::list get_column_info();

  // Arrow
  void arrow_schema(struct ArrowSchema* out, int64_t infer_rows);
  int64_t fetch_arrow(struct ArrowArray* out, int64_t n_max);
  // At most `n_max` rows, all for a negative `n_max`, typed for a data frame,
  // as a stream of arrays of at most `chunk_size` rows; returns the row count
  // and describes the columns in `columns`
  int64_t fetch_arrow_df(
    struct ArrowArrayStream* out,
    ArrowDfColumns& columns,
    int64_t n_max,
    int64_t chunk_size
  );
  void bind_arrow(
    struct ArrowArrayStream* stream,
    const std::vector<int>& param_indexes
  );

private:
  void validate_params(const cpp11::list& params) const;
};

#endif  // __RDBI_DB_RESULT__
