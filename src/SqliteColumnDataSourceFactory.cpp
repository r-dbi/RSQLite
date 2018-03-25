#include "pch.h"
#include "SqliteColumnDataSourceFactory.h"
#include "SqliteColumnDataSource.h"

SqliteColumnDataSourceFactory::SqliteColumnDataSourceFactory(sqlite3_stmt* stmt_) :
  stmt(stmt_)
{
}

SqliteColumnDataSourceFactory::~SqliteColumnDataSourceFactory() {
}

DbColumnDataSource* SqliteColumnDataSourceFactory::create(const int j) {
  return new SqliteColumnDataSource(stmt, j);
}
