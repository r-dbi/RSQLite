#ifndef RSQLITE_MAIN_THREAD_H
#define RSQLITE_MAIN_THREAD_H

#include <string>

// R's API may only be called on R's main thread. Arrow consumers such as the
// Acero engine of the arrow package call the callbacks of an Arrow stream on
// worker threads, while R's main thread waits for them.

// Whether the calling thread is R's main thread, recorded when the package
// loads
bool rsqlite_on_main_thread();

// Raises an R warning on R's main thread. Elsewhere, where R can't be called,
// throws the message as a C++ exception, which an Arrow stream reports as its
// error.
void rsqlite_warning(const std::string& message);

#endif  // RSQLITE_MAIN_THREAD_H
