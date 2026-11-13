#include "pch.h"
#include "DbColumnDataSource.h"

DbColumnDataSource::DbColumnDataSource(const int j_) : j(j_) {}

DbColumnDataSource::~DbColumnDataSource() {}

int64_t DbColumnDataSource::get_n_invalid_strings() const {
  return 0;
}

int DbColumnDataSource::get_j() const {
  return j;
}
