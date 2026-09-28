#include "pch.h"
#include "CoercionLog.h"
#include "sqlite3-cpp.h"

using namespace cpp11::literals;

void CoercionLog::record(int column_type, COERCION_REASON reason, int64_t row) {
  Entry* entry = NULL;
  for (size_t i = 0; i < entries.size(); ++i) {
    if (entries[i].column_type == column_type && entries[i].reason == reason) {
      entry = &entries[i];
      break;
    }
  }
  if (entry == NULL) {
    entries.push_back(Entry());
    entry = &entries.back();
    entry->column_type = column_type;
    entry->reason = reason;
    entry->count = 0;
    entry->last[0] = 0;
    entry->last[1] = 0;
  }

  ++entry->count;
  if (entry->head.size() < N_HEAD) {
    entry->head.push_back(row);
  }
  entry->last[0] = entry->last[1];
  entry->last[1] = row;
}

bool CoercionLog::empty() const {
  return entries.empty();
}

void CoercionLog::clear() {
  entries.clear();
}

cpp11::writable::list CoercionLog::as_list() const {
  cpp11::writable::list out;
  for (size_t i = 0; i < entries.size(); ++i) {
    const Entry& entry = entries[i];

    cpp11::writable::doubles rows(entry.head.size());
    for (size_t k = 0; k < entry.head.size(); ++k) {
      rows[k] = static_cast<double>(entry.head[k]);
    }

    cpp11::sexp last(R_NilValue);
    if (static_cast<size_t>(entry.count) > entry.head.size()) {
      cpp11::writable::doubles last_rows(2);
      last_rows[0] = static_cast<double>(entry.last[0]);
      last_rows[1] = static_cast<double>(entry.last[1]);
      last = last_rows;
    }

    cpp11::writable::list item(
      { "class"_nm = cpp11::r_string(format_column_type(entry.column_type)),
        "reason"_nm = cpp11::r_string(format_reason(entry.reason)),
        "count"_nm = static_cast<double>(entry.count),
        "rows"_nm = rows,
        "last"_nm = last }
    );
    out.push_back(item);
  }
  return out;
}

const char* CoercionLog::format_column_type(int column_type) {
  switch (column_type) {
  case SQLITE_INTEGER:
    return "integer";
  case SQLITE_FLOAT:
    return "real";
  case SQLITE_TEXT:
    return "string";
  case SQLITE_BLOB:
    return "blob";
  default:
    return "null";
  }
}

const char* CoercionLog::format_reason(COERCION_REASON reason) {
  switch (reason) {
  case CR_CONVERTED:
    return "converted";
  case CR_INVALID_UTF8:
    return "invalid_utf8";
  case CR_UNPARSABLE:
    return "unparsable";
  case CR_OUT_OF_RANGE:
    return "out_of_range";
  }
  return "converted";
}
