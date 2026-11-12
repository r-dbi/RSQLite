#ifndef __RDBI_DB_RESULT__
#define __RDBI_DB_RESULT__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/scoped_ptr.hpp>

#include "DbResultImplDecl.h"

class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;
struct ArrowArray;
struct ArrowSchema;

// Owned by the external pointer of a result, see result_create()
class DbResult;
typedef boost::shared_ptr<DbResult> DbResultPtr;

// DbResult --------------------------------------------------------------------

class DbResult : boost::noncopyable {
  DbConnectionPtr pConn_;
  // Set while a fetch or a bind runs, see run_guarded() in DbResult.cpp
  bool busy_;

protected:
  boost::scoped_ptr<DbResultImpl> impl;

protected:
  DbResult(const DbConnectionPtr& pConn);

public:
  // Virtual, because a DbResultPtr deletes a SqliteResult through a DbResult*
  virtual ~DbResult();

public:
  void close();

  bool complete() const;
  bool is_active() const;
  bool busy() const;
  int n_rows_fetched();
  int n_rows_affected();

  void bind(const cpp11::list& params);
  cpp11::list fetch(int n_max = -1);
  void fetch_arrow_chunk(
    struct ArrowArray* array,
    struct ArrowSchema* schema,
    int n_max
  );

  cpp11::list get_column_info();

private:
  void validate_params(const cpp11::list& params) const;
};

#endif  // __RDBI_DB_RESULT__
