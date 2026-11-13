#ifndef __RDBI_DB_RESULT__
#define __RDBI_DB_RESULT__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/scoped_ptr.hpp>
#include <string>
#include <vector>

#include "DbResultImplDecl.h"

class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;
struct ArrowArray;
struct ArrowSchema;
struct ArrowArrayStream;

// Owned by the external pointer of a result, see result_create()
class DbResult;
typedef boost::shared_ptr<DbResult> DbResultPtr;

// DbResult --------------------------------------------------------------------

class DbResult : boost::noncopyable {
  DbConnectionPtr pConn_;
  // Set while a fetch or a bind runs, see run_guarded() in DbResult.cpp
  bool busy_;
  // How the rows of the result are fetched, see claim_fetch_kind()
  std::string fetch_kind_;
  // Set by clear()
  bool cleared_;

protected:
  boost::scoped_ptr<DbResultImpl> impl;

protected:
  DbResult(const DbConnectionPtr& pConn);

public:
  // Virtual, because a DbResultPtr deletes a SqliteResult through a DbResult*
  virtual ~DbResult();

public:
  void close();
  // For dbClearResult() and R's garbage collector,
  // which drop R's share of the result:
  // an Arrow stream that shares it reads on,
  // but it no longer counts as in use for dbDisconnect()
  void clear();
  // An Arrow stream that reads the result keeps its connection open,
  // see DbConnection::add_stream()
  void add_stream();
  void remove_stream();
  // Whether an Arrow chunk is kept for the next Arrow fetch,
  // as when its warning exited
  bool arrow_chunk_kept() const;

  bool complete() const;
  bool is_active() const;
  bool busy() const;
  bool connection_valid() const;
  int executions() const;
  int64_t n_rows_fetched();
  int64_t n_rows_affected();

  void bind(const cpp11::list& params);
  void bind_arrow(
    struct ArrowArrayStream* stream,
    const std::vector<int>& indexes
  );
  cpp11::list fetch(int n_max = -1);
  void fetch_arrow_chunk(
    struct ArrowArray* array,
    struct ArrowSchema* schema,
    int n_max
  );
  void arrow_schema(struct ArrowSchema* schema, int n_max);
  // Claims the result for `kind` of fetch, unless another kind has claimed it;
  // returns the kind that holds the claim, see claim_fetch_kind() in R
  std::string claim_fetch_kind(const std::string& kind);

  cpp11::list get_column_info();

private:
  void validate_params(const cpp11::list& params) const;
};

#endif  // __RDBI_DB_RESULT__
