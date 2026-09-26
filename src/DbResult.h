#ifndef __RDBI_DB_RESULT__
#define __RDBI_DB_RESULT__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/scoped_ptr.hpp>

#include "DbResultImplDecl.h"

class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;

class DbResult;
typedef boost::shared_ptr<DbResult> DbResultPtr;

struct ArrowSchema;
struct ArrowArray;
struct ArrowArrayStream;

// DbResult --------------------------------------------------------------------

class DbResult : boost::noncopyable {
  DbConnectionPtr pConn_;

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
  int n_rows_fetched();
  int n_rows_affected();

  void bind(const cpp11::list& params);
  cpp11::list fetch(int n_max = -1);

  cpp11::list get_column_info();

  // Arrow
  void arrow_schema(struct ArrowSchema* out, int64_t infer_rows);
  int64_t fetch_arrow(struct ArrowArray* out, int64_t n_max);
  void bind_arrow(
    struct ArrowArrayStream* stream,
    const std::vector<int>& param_indexes
  );

private:
  void validate_params(const cpp11::list& params) const;
};

#endif  // __RDBI_DB_RESULT__
