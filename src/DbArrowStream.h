#ifndef RSQLITE_DBARROWSTREAM_H
#define RSQLITE_DBARROWSTREAM_H

#include "DbResult.h"

struct ArrowArrayStream;

// Initializes `out` as a lazy Arrow stream over `result`: every get_next()
// fetches the next chunk of at most `chunk_size` rows from the live result.
// The stream shares ownership of the result, so it stays readable after the
// R result object has been cleared, and it drops its share once consumed.
void db_arrow_stream_init(
  struct ArrowArrayStream* out,
  const DbResultPtr& result,
  int64_t chunk_size
);

// Initializes `out` as a stream over all remaining rows of `result`, fetched
// up front as arrays of at most `chunk_size` rows, so that the row count is
// known before the conversion starts; returns that count.
// Each array is moved out when it is requested, so a consumer that converts
// the arrays one by one frees each of them before it asks for the next.
int64_t db_arrow_buffered_stream_init(
  struct ArrowArrayStream* out,
  const DbResultPtr& result,
  int64_t chunk_size
);

#endif  // RSQLITE_DBARROWSTREAM_H
