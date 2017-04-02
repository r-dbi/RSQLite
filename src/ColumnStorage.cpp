#include "pch.h"
#include "ColumnStorage.h"
#include "SqliteColumnDataSource.h"
#include "integer64.h"


using namespace Rcpp;

ColumnStorage::ColumnStorage(DATA_TYPE dt_, const int capacity_, const int n_max_,
                             const SqliteColumnDataSource& source_)
  :
  i(0),
  dt(dt_),
  n_max(n_max_),
  source(source_)
{
  data = allocate(get_new_capacity(capacity_), dt);
}

ColumnStorage::~ColumnStorage() {
}

ColumnStorage* ColumnStorage::append_col() {
  if (source.is_null()) return append_null();
  return append_data();
}

DATA_TYPE ColumnStorage::get_data_type() const {
  if (dt == DT_UNKNOWN) return source.get_decl_data_type();
  return dt;
}

SEXP ColumnStorage::allocate(const int length, DATA_TYPE dt) {
  SEXPTYPE type = sexptype_from_datatype(dt);
  RObject class_ = class_from_datatype(dt);

  SEXP ret = Rf_allocVector(type, length);
  if (!Rf_isNull(class_)) Rf_setAttrib(ret, R_ClassSymbol, class_);
  return ret;
}

int ColumnStorage::copy_to(SEXP x, DATA_TYPE dt, const int pos) const {
  R_xlen_t n = Rf_xlength(x);
  int src, tgt;
  R_xlen_t capacity = get_capacity();
  for (src = 0, tgt = pos; src < capacity && src < i && tgt < n; ++src, ++tgt) {
    copy_value(x, dt, tgt, src);
  }

  for (; src < i && tgt < n; ++src, ++tgt) {
    fill_default_value(x, dt, tgt);
  }

  return src;
}

R_xlen_t ColumnStorage::get_capacity() const {
  return Rf_xlength(data);
}

int ColumnStorage::get_new_capacity(const R_xlen_t desired_capacity) const {
  if (n_max < 0) {
    const R_xlen_t MIN_DATA_CAPACITY = 100;
    return std::max(desired_capacity, MIN_DATA_CAPACITY);
  }
  else {
    return std::max(desired_capacity, R_xlen_t(1));
  }
}

ColumnStorage* ColumnStorage::append_null() {
  if (i < get_capacity()) fill_default_value();
  ++i;
  return this;
}

void ColumnStorage::fill_default_value() {
  fill_default_value(data, dt, i);
}

ColumnStorage* ColumnStorage::append_data() {
  if (dt == DT_UNKNOWN) return append_data_to_new(dt);
  if (i >= get_capacity()) return append_data_to_new(dt);
  if (dt == DT_INT && source.get_data_type() == DT_INT64) return append_data_to_new(DT_INT64);

  fetch_value();
  ++i;
  return this;
}

ColumnStorage* ColumnStorage::append_data_to_new(DATA_TYPE new_dt) {
  if (new_dt == DT_UNKNOWN) new_dt = source.get_data_type();

  R_xlen_t desired_capacity = (n_max < 0) ? (get_capacity() * 2) : (n_max - i);

  ColumnStorage* spillover = new ColumnStorage(new_dt, desired_capacity, n_max, source);
  return spillover->append_data();
}

void ColumnStorage::fetch_value() {
  switch (dt) {
  case DT_INT:
    source.fetch_int(data, i);
    break;

  case DT_INT64:
    source.fetch_int64(data, i);
    break;

  case DT_REAL:
    source.fetch_real(data, i);
    break;

  case DT_STRING:
    source.fetch_string(data, i);
    break;

  case DT_BLOB:
    source.fetch_blob(data, i);
    break;

  default:
    stop("NYI");
  }
}

SEXPTYPE ColumnStorage::sexptype_from_datatype(DATA_TYPE dt) {
  switch (dt) {
  case DT_UNKNOWN:
    return NILSXP;

  case DT_BOOL:
    return LGLSXP;

  case DT_INT:
    return INTSXP;

  case DT_INT64:
  case DT_REAL:
    return REALSXP;

  case DT_STRING:
    return STRSXP;

  case DT_BLOB:
    return VECSXP;

  default:
    stop("Unknown type %d", dt);
  }
}

Rcpp::RObject ColumnStorage::class_from_datatype(DATA_TYPE dt) {
  switch (dt) {
  case DT_INT64:
    return CharacterVector::create("integer64");

  default:
    return R_NilValue;
  }
}

void ColumnStorage::fill_default_value(SEXP data, DATA_TYPE dt, R_xlen_t i) {
  switch (dt) {
  case DT_BOOL:
    LOGICAL(data)[i] = NA_LOGICAL;
    break;

  case DT_INT:
    INTEGER(data)[i] = NA_INTEGER;
    break;

  case DT_INT64:
    INTEGER64(data)[i] = NA_INTEGER64;
    break;

  case DT_REAL:
    REAL(data)[i] = NA_REAL;
    break;

  case DT_STRING:
    SET_STRING_ELT(data, i, NA_STRING);
    break;

  case DT_BLOB:
    SET_VECTOR_ELT(data, i, R_NilValue);
    break;
  }
}

void ColumnStorage::copy_value(SEXP x, DATA_TYPE dt, const int tgt, const int src) const {
  if (Rf_isNull(data)) {
    fill_default_value(x, dt, tgt);
  }
  else {
    switch (dt) {
    case DT_INT:
      INTEGER(x)[tgt] = INTEGER(data)[src];
      break;

    case DT_INT64:
      switch (TYPEOF(data)) {
      case INTSXP:
        INTEGER64(x)[tgt] = INTEGER(data)[src];
        break;

      case REALSXP:
        INTEGER64(x)[tgt] = INTEGER64(data)[src];
        break;
      }
      break;

    case DT_REAL:
      REAL(x)[tgt] = REAL(data)[src];
      break;

    case DT_STRING:
      SET_STRING_ELT(x, tgt, STRING_ELT(data, src));
      break;

    case DT_BLOB:
      SET_VECTOR_ELT(x, tgt, VECTOR_ELT(data, src));
      break;

    default:
      stop("NYI: default");
    }
  }
}
