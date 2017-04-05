#include "pch.h"
#include "SqliteColumn.h"
#include "ColumnStorage.h"
#include "SqliteColumnDataSource.h"


SqliteColumn::SqliteColumn(DATA_TYPE dt, int n_max_, sqlite3_stmt* stmt_, int j_)
  : source(new SqliteColumnDataSource(stmt_, j_)),
    i(0),
    n(0)
{
  if (dt == DT_BOOL)
    dt = DT_UNKNOWN;
  storage.push_back(new ColumnStorage(dt, 0, n_max_, *source));
}

SqliteColumn::~SqliteColumn() {
}

void SqliteColumn::set_col_value() {
  ColumnStorage* last = get_last_storage();
  DATA_TYPE dt = last->get_item_data_type();
  data_types_seen.insert(dt);

  ColumnStorage* next = last->append_col();
  if (last != next) storage.push_back(next);
}

void SqliteColumn::finalize(const int n_) {
  n = n_;
}

void SqliteColumn::warn_type_conflicts(const String& name) const {
  std::set<DATA_TYPE> my_data_types_seen = data_types_seen;
  DATA_TYPE dt = get_last_storage()->get_data_type();

  switch (dt) {
  case DT_REAL:
    my_data_types_seen.erase(DT_INT);
    break;

  case DT_INT64:
    my_data_types_seen.erase(DT_INT);
    break;
  }

  my_data_types_seen.erase(DT_UNKNOWN);
  my_data_types_seen.erase(DT_BOOL);
  my_data_types_seen.erase(dt);

  if (my_data_types_seen.size() == 0) return;

  String name_utf8 = name;
  name_utf8.set_encoding(CE_UTF8);

  std::stringstream ss;
  ss << "Column `" << name_utf8.get_cstring() << "`: " <<
     "mixed type, first seen values of type " << format_data_type(dt) << ", " <<
     "coercing other values of type ";

  bool first = true;
  for (std::set<DATA_TYPE>::const_iterator it = my_data_types_seen.begin(); it != my_data_types_seen.end(); ++it) {
    if (!first) ss << ", ";
    else first = false;
    ss << format_data_type(*it);
  }

  warning(ss.str());
}

SqliteColumn::operator SEXP() const {
  DATA_TYPE dt = get_last_storage()->get_data_type();
  SEXP ret = ColumnStorage::allocate(n, dt);
  int pos = 0;
  for (size_t k = 0; k < storage.size(); ++k) {
    const ColumnStorage& current = storage[k];
    pos += current.copy_to(ret, dt, pos);
  }
  return ret;
}

DATA_TYPE SqliteColumn::get_type() const {
  const DATA_TYPE dt = get_last_storage()->get_data_type();
  return dt;
}

const char* SqliteColumn::format_data_type(const DATA_TYPE dt) {
  switch (dt) {
  case DT_UNKNOWN:
    return "unknown";
  case DT_BOOL:
    return "boolean";
  case DT_INT:
    return "integer";
  case DT_INT64:
    return "integer64";
  case DT_REAL:
    return "real";
  case DT_STRING:
    return "string";
  case DT_BLOB:
    return "blob";
  default:
    return "<unknown type>";
  }
}

ColumnStorage* SqliteColumn::get_last_storage() {
  return &storage.end()[-1];
}

const ColumnStorage* SqliteColumn::get_last_storage() const {
  return &storage.end()[-1];
}
