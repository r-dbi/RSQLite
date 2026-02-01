#include "pch.h"
#include "SqliteColumnDataSourceFactory.h"
#include "SqliteColumnDataSource.h"

SqliteColumnDataSourceFactory::SqliteColumnDataSourceFactory(
  sqlite3_stmt* stmt_,
  bool with_alt_types_
)
    : stmt(stmt_), with_alt_types(with_alt_types_) {}

SqliteColumnDataSourceFactory::~SqliteColumnDataSourceFactory() {}

DbColumnDataSource* SqliteColumnDataSourceFactory::create(const int j) {
  return new SqliteColumnDataSource(stmt, j, with_alt_types);
}
