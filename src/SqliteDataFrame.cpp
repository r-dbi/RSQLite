#include "pch.h"
#include "SqliteDataFrame.h"
#include "SqliteColumnDataSourceFactory.h"

SqliteDataFrame::SqliteDataFrame(
  sqlite3_stmt* stmt,
  std::vector<std::string> names,
  const int n_max_,
  const std::vector<DATA_TYPE>& types,
  bool with_alt_types,
  bool check_utf8
)
    : DbDataFrame(
        new SqliteColumnDataSourceFactory(stmt, with_alt_types, check_utf8),
        names,
        n_max_,
        types
      ) {}

SqliteDataFrame::~SqliteDataFrame() {}
