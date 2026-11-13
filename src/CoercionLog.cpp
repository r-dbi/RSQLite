#include "pch.h"
#include "CoercionLog.h"
#include "sqlite3-cpp.h"
#include <algorithm>
#include <iterator>

using namespace cpp11::literals;

void CoercionLog::record(int column_type, COERCION_REASON reason, int64_t row) {
  Entry* entry = find(column_type, reason);
  if (entry == NULL) {
    entries.push_back(Entry());
    entry = &entries.back();
    entry->column_type = column_type;
    entry->reason = reason;
    entry->count = 0;
  }

  ++entry->count;
  if (entry->rows.size() < N_ROWS) {
    entry->rows.push_back(row);
  }
}

void CoercionLog::merge(
  int column_type,
  COERCION_REASON from,
  COERCION_REASON to
) {
  Entry* source = find(column_type, from);
  if (source == NULL) {
    return;
  }
  Entry* target = find(column_type, to);
  if (target == NULL) {
    source->reason = to;
    return;
  }

  target->count += source->count;
  // Each keeps its first rows in order,
  // so the first rows of both are the first of the two lists merged
  std::vector<int64_t> rows;
  std::merge(
    target->rows.begin(),
    target->rows.end(),
    source->rows.begin(),
    source->rows.end(),
    std::back_inserter(rows)
  );
  if (rows.size() > N_ROWS) {
    rows.resize(N_ROWS);
  }
  target->rows.swap(rows);

  // The groups are in the order of their first rows:
  // the merged one takes the slot of the earlier of the two
  const size_t i_source = static_cast<size_t>(source - &entries[0]);
  const size_t i_target = static_cast<size_t>(target - &entries[0]);
  if (i_source < i_target) {
    std::swap(entries[i_source], entries[i_target]);
    entries.erase(entries.begin() + i_target);
  } else {
    entries.erase(entries.begin() + i_source);
  }
}

bool CoercionLog::empty() const {
  return entries.empty();
}

void CoercionLog::clear() {
  entries.clear();
}

CoercionLog::Entry* CoercionLog::find(int column_type, COERCION_REASON reason) {
  for (size_t i = 0; i < entries.size(); ++i) {
    if (entries[i].column_type == column_type && entries[i].reason == reason) {
      return &entries[i];
    }
  }
  return NULL;
}

static const char* format_column_type(int column_type) {
  switch (column_type) {
  case SQLITE_INTEGER:
    return "integer";
  case SQLITE_FLOAT:
    return "real";
  case SQLITE_TEXT:
    return "text";
  default:
    return "blob";
  }
}

static const char* format_reason(COERCION_REASON reason) {
  switch (reason) {
  case CR_OUT_OF_RANGE:
    return "out_of_range";
  case CR_INVALID_UTF8:
    return "invalid_utf8";
  case CR_UNPARSABLE:
    return "unparsable";
  case CR_NULL_TYPE:
    return "null_type";
  case CR_CONVERTED:
  default:
    return "converted";
  }
}

cpp11::writable::list CoercionLog::as_list() const {
  cpp11::writable::list out(static_cast<R_xlen_t>(entries.size()));
  for (size_t i = 0; i < entries.size(); ++i) {
    const Entry& entry = entries[i];
    // Doubles hold row numbers and counts beyond 32 bits exactly up to 2^53
    cpp11::writable::doubles rows(static_cast<R_xlen_t>(entry.rows.size()));
    for (size_t k = 0; k < entry.rows.size(); ++k) {
      rows[k] = static_cast<double>(entry.rows[k]);
    }
    out[i] = cpp11::writable::list(
      { "class"_nm = format_column_type(entry.column_type),
        "reason"_nm = format_reason(entry.reason),
        "count"_nm = static_cast<double>(entry.count),
        "rows"_nm = rows }
    );
  }
  return out;
}
