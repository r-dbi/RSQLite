#ifndef __RDBI_DB_RESULT__
#define __RDBI_DB_RESULT__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/scoped_ptr.hpp>
#include <vector>

#include <atomic>
#include <functional>

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
public:
  // The thread that holds the result while one of its fetches or binds runs
  enum BusyOwner { BUSY_NONE = 0, BUSY_MAIN_THREAD = 1, BUSY_OTHER_THREAD = 2 };

private:
  DbConnectionPtr pConn_;
  // A BusyOwner, set while a fetch or a bind runs, see run_guarded() in
  // DbResult.cpp
  std::atomic<int> busy_;
  // Counts the R conditions rethrown as C++ exceptions from an Arrow stream of
  // this result, see db_arrow_stream_read_from_cpp(); for the tests
  int64_t rethrown_unwinds_;

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
  BusyOwner busy_owner() const;
  // For the tests: runs `body` while the calling thread holds the result busy
  void hold_busy(std::function<void()> body);
  // Finalizes the statement, which needs no R; on any thread
  void finalize_statement();
  void count_rethrown_unwind();
  int64_t rethrown_unwinds() const;
  // Counts the executions of the statement with new parameters:
  // bind() and bind_arrow() start a new one
  int64_t executions() const;
  int64_t n_rows_fetched();
  int n_rows_affected();

  void bind(const cpp11::list& params);
  cpp11::list fetch(int n_max = -1);

  cpp11::list get_column_info();

  // Arrow
  // A stream passes the execution whose rows it reads, see executions(), so
  // that a result bound to new parameters fails it; and gets the completion
  // of the result along with the chunk
  void arrow_schema(
    struct ArrowSchema* out,
    int64_t infer_rows,
    int64_t stream_execution = -1
  );
  int64_t fetch_arrow(
    struct ArrowArray* out,
    int64_t n_max,
    int64_t stream_execution = -1,
    bool* complete = NULL
  );
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
  void check_stream_execution(int64_t stream_execution) const;
  void precheck_stream_execution(int64_t stream_execution) const;
};

#endif  // __RDBI_DB_RESULT__
