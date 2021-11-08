#define STRICT_R_HEADERS
#define R_NO_REMAP

#ifndef DB_COLUMNDATASOURCEFACTORY_H
#define DB_COLUMNDATASOURCEFACTORY_H

class DbColumnDataSource;

class DbColumnDataSourceFactory {
protected:
  DbColumnDataSourceFactory();

public:
  virtual ~DbColumnDataSourceFactory();

public:
  virtual DbColumnDataSource* create(const int j) = 0;
};

#endif //DB_COLUMNDATASOURCEFACTORY_H
