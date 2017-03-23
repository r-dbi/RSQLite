#include <RSQLite.h>
#include "SqliteDataFrame.h"
#include "SqliteColumn.h"
#include <boost/bind.hpp>

SqliteDataFrame::SqliteDataFrame(sqlite3_stmt* stmt_, std::vector<std::string> names_, const int n_max_,
                                 const std::vector<SEXPTYPE>& types_)
  : stmt(stmt_),
    n_max(n_max_),
    i(0),
    names(names_)
{
  data.reserve(types_.size());
  for (size_t j = 0; j < types_.size(); ++j) {
    SqliteColumn x(types_[j], j, n_max);
    data.push_back(x);
  }
}

SqliteDataFrame::~SqliteDataFrame() {
}

void SqliteDataFrame::set_col_values() {
  for (size_t j = 0; j < data.size(); ++j) {
    data[j].set_col_value(stmt);
  }
}

bool SqliteDataFrame::advance() {
  ++i;

  if (i % 1000 == 0)
    checkUserInterrupt();

  return (n_max < 0 || i < n_max);
}

List SqliteDataFrame::get_data(std::vector<SEXPTYPE>& types_) {
  // Trim back to what we actually used
  finalize_cols();

  types_.clear();
  std::transform(data.begin(), data.end(), std::back_inserter(types_), std::mem_fun_ref(&SqliteColumn::get_type));

  List out(data.begin(), data.end());
  out.attr("names") = names;
  out.attr("class") = "data.frame";
  out.attr("row.names") = IntegerVector::create(NA_INTEGER, -i);
  return out;
}

void SqliteDataFrame::finalize_cols() {
  std::for_each(data.begin(), data.end(), boost::bind(&SqliteColumn::finalize, _1, stmt, i));
}
