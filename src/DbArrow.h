#ifndef RSQLITE_DBARROW_H
#define RSQLITE_DBARROW_H

// Helpers shared by the Arrow code paths.
//
// The functions here throw C++ exceptions, never R errors,
// which cpp11 turns into R errors at the entry point:
// a longjmp would skip the destructors of the arrays under construction.

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

#endif  // RSQLITE_DBARROW_H
