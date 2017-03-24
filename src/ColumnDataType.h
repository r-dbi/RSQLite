#ifndef RSQLITE_COLUMNDATATYPE_H
#define RSQLITE_COLUMNDATATYPE_H

#include <Rcpp.h>

enum DATA_TYPE {
  DT_UNKNOWN = NILSXP,
  DT_BOOL = LGLSXP,
  DT_INT = INTSXP,
  DT_REAL = REALSXP,
  DT_STRING = STRSXP,
  DT_BLOB = VECSXP
};

inline DATA_TYPE datatype_from_sexptype(const SEXPTYPE type) {
  return (DATA_TYPE)type;
}
inline SEXPTYPE sexptype_from_datatype(const DATA_TYPE dt) {
  return (SEXPTYPE)dt;
}

#endif // RSQLITE_COLUMNDATATYPE_H
