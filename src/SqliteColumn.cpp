#include <RSQLite.h>
#include "SqliteColumn.h"
#include "ColumnStorage.h"
#include "SqliteColumnDataSource.h"


SqliteColumn::SqliteColumn(SEXPTYPE dt_, int n_max_, sqlite3_stmt* stmt_, int j_)
  : source(new SqliteColumnDataSource(stmt_, j_)),
    n_max(n_max_),
    i(0),
    n(init_n())
{
  DATA_TYPE dt = datatype_from_sexptype(dt_);
  storage.push_back(new ColumnStorage(dt, init_n(), n_max_, *source));
}

SqliteColumn::~SqliteColumn() {
}

int SqliteColumn::init_n() const {
  if (n_max >= 0)
    return n_max;

  return 100;
}

void SqliteColumn::set_col_value() {
  ColumnStorage* last = get_last_storage();
  ColumnStorage* next = last->append_col();
  if (last != next) storage.push_back(next);
}

ColumnStorage* SqliteColumn::get_last_storage() {
  return &storage.end()[-1];
}

const ColumnStorage* SqliteColumn::get_last_storage() const {
  return &storage.end()[-1];
}

void SqliteColumn::finalize(const int n_) {
  n = n_;
}

SqliteColumn::operator SEXP() const {
  SEXP ret = get_last_storage()->allocate_final(n);
  int pos = 0;
  for (size_t k = 0; k < storage.size(); ++k) {
    const ColumnStorage& current = storage[k];
    pos += current.copy_to(ret, pos, n);
  }
  return ret;
}

SEXPTYPE SqliteColumn::get_type() const {
  return sexptype_from_datatype(get_last_storage()->get_data_type());
}
