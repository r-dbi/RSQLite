#ifndef RSQLITE_DBCOLUMNFACTORY_H
#define RSQLITE_DBCOLUMNFACTORY_H

class DbColumnDataSource;

class DbColumnDataSourceFactory {
protected:
  DbColumnDataSourceFactory();

public:
  virtual ~DbColumnDataSourceFactory();

public:
  virtual DbColumnDataSource* create(const int j) = 0;
};

#endif //RSQLITE_DBCOLUMNFACTORY_H
