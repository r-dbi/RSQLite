#include <RSQLite.h>
#include "SqliteColumn.h"
#include "ColumnStorage.h"
#include "SqliteColumnDataSource.h"


SqliteColumn::SqliteColumn(DATA_TYPE dt, int n_max_, sqlite3_stmt* stmt_, int j_)
  : source(new SqliteColumnDataSource(stmt_, j_)),
    i(0),
    n(0)
{
  storage.push_back(new ColumnStorage(dt, 0, n_max_, *source));
}

SqliteColumn::~SqliteColumn() {
}

void SqliteColumn::set_col_value() {
  ColumnStorage* last = get_last_storage();
  ColumnStorage* next = last->append_col();
  if (last != next) storage.push_back(next);
}

void SqliteColumn::finalize(const int n_) {
  n = n_;
}

SqliteColumn::operator SEXP() const {
  DATA_TYPE dt = get_last_storage()->get_data_type();
  SEXP ret = ColumnStorage::allocate(n, dt);
  int pos = 0;
  for (size_t k = 0; k < storage.size(); ++k) {
    const ColumnStorage& current = storage[k];
    pos += current.copy_to(ret, dt, pos, n);
  }
  return ret;
}

DATA_TYPE SqliteColumn::get_type() const {
  return get_last_storage()->get_data_type();
}

ColumnStorage* SqliteColumn::get_last_storage() {
  return &storage.end()[-1];
}

const ColumnStorage* SqliteColumn::get_last_storage() const {
  return &storage.end()[-1];
}
