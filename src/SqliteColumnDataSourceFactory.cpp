#include "pch.h"
#include "SqliteColumnDataSourceFactory.h"
#include "SqliteColumnDataSource.h"

SqliteColumnDataSourceFactory::SqliteColumnDataSourceFactory(
  sqlite3_stmt* stmt_,
  bool with_alt_types_,
  bool check_utf8_
)
    : stmt(stmt_), with_alt_types(with_alt_types_), check_utf8(check_utf8_) {}

SqliteColumnDataSourceFactory::~SqliteColumnDataSourceFactory() {}

DbColumnDataSource* SqliteColumnDataSourceFactory::create(const int j) {
  return new SqliteColumnDataSource(stmt, j, with_alt_types, check_utf8);
}
