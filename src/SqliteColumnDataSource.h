#ifndef RSQLITE_SQLITECOLUMNDATASOURCE_H
#define RSQLITE_SQLITECOLUMNDATASOURCE_H

#include "sqlite3.h"

class SqliteColumnDataSource {
  struct sqlite3_stmt* stmt;
  const int j;

public:
  SqliteColumnDataSource(struct sqlite3_stmt* stmt_, const int j_);

public:
  sqlite3_stmt* get_stmt() const;
  int get_j() const;
};

#endif // RSQLITE_SQLITECOLUMNDATASOURCE_H
