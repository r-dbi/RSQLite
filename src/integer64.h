#ifndef RSQLITE_INTEGER64_H
#define RSQLITE_INTEGER64_H

#define NA_INTEGER64 (0x8000000000000000)

inline int64_t* INTEGER64(SEXP x) {
  return reinterpret_cast<int64_t*>(REAL(x));
}

#endif // RSQLITE_INTEGER64_H
