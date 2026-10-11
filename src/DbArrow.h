#ifndef RSQLITE_DBARROW_H
#define RSQLITE_DBARROW_H

// Helpers shared by the Arrow code paths.
//
// The functions here throw C++ exceptions, never R errors: they are also used
// inside ArrowArrayStream callbacks, where a longjmp would skip the C frames of
// the stream consumer.

#include <stdexcept>
#include <string>

#include "nanoarrow/nanoarrow.h"
#include "nanoarrow/nanoarrow.hpp"

inline void check_arrow(
  int code,
  const char* what,
  const struct ArrowError* error = NULL
) {
  if (code == NANOARROW_OK) {
    return;
  }
  std::string message(what);
  if (error != NULL && error->message[0] != '\0') {
    message += ": ";
    message += error->message;
  }
  throw std::runtime_error(message);
}

inline std::string arrow_type_name(const struct ArrowSchema* schema) {
  char buffer[128];
  ArrowSchemaToString(schema, buffer, sizeof(buffer), 0);
  return std::string(buffer);
}

inline struct ArrowStringView arrow_string_view(
  const char* data,
  int64_t size
) {
  struct ArrowStringView view;
  view.data = data;
  view.size_bytes = size;
  return view;
}

inline struct ArrowBufferView arrow_buffer_view(
  const void* data,
  int64_t size
) {
  struct ArrowBufferView view;
  view.data.data = data;
  view.size_bytes = size;
  return view;
}

#endif  // RSQLITE_DBARROW_H
