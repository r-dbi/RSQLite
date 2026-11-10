#ifndef RSQLITE_DBARROWSTREAM_H
#define RSQLITE_DBARROWSTREAM_H

#include "DbResult.h"

struct ArrowArrayStream;

// Initializes `out` as a lazy Arrow stream over `result`: every get_next()
// fetches the next chunk of at most `chunk_size` rows from the live result.
// The stream shares ownership of the result, so it stays readable after the
// R result object has been cleared, while other queries run on the connection,
// and after the connection has been closed, which SQLite defers until the
// statement is finalized; it drops its share once consumed.
// It reads the rows of the current execution: once the result is bound to
// new parameters, it fails.
void db_arrow_stream_init(
  struct ArrowArrayStream* out,
  const DbResultPtr& result,
  int64_t chunk_size
);

#endif  // RSQLITE_DBARROWSTREAM_H
