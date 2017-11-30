#ifndef RSQLITE_SQLITECOLUMNFACTORY_H
#define RSQLITE_SQLITECOLUMNFACTORY_H

#include "sqlite3.h"
#include "DbColumnDataSourceFactory.h"

class SqliteColumnDataSourceFactory : public DbColumnDataSourceFactory {
  sqlite3_stmt* stmt;

public:
  SqliteColumnDataSourceFactory(sqlite3_stmt* stmt_);
  ~SqliteColumnDataSourceFactory();

public:
  DbColumnDataSource* create(const int j);
};

#endif //RSQLITE_SQLITECOLUMNFACTORY_H
