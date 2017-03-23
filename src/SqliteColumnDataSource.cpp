#include "SqliteColumnDataSource.h"

SqliteColumnDataSource::SqliteColumnDataSource(sqlite3_stmt* stmt_, const int j_)
  :
  stmt(stmt_),
  j(j_)
{
}

sqlite3_stmt* SqliteColumnDataSource::get_stmt() const {
  return stmt;
}

int SqliteColumnDataSource::get_j() const {
  return j;
}
