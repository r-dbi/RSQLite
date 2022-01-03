#ifndef RSQLITE_SQLITECOLUMNFACTORY_H
#define RSQLITE_SQLITECOLUMNFACTORY_H

#include "sqlite3-cpp.h"
#include "DbColumnDataSourceFactory.h"

class SqliteColumnDataSourceFactory : public DbColumnDataSourceFactory {
  sqlite3_stmt* stmt;
  bool with_alt_types;

public:
  SqliteColumnDataSourceFactory(sqlite3_stmt* stmt_, bool with_alt_types_);
  ~SqliteColumnDataSourceFactory();

public:
  DbColumnDataSource* create(const int j);
};

#endif //RSQLITE_SQLITECOLUMNFACTORY_H
