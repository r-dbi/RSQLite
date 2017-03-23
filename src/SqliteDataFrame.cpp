#include <RSQLite.h>
#include "SqliteDataFrame.h"
#include "SqliteColumn.h"
#include <boost/bind.hpp>

SqliteDataFrame::SqliteDataFrame(sqlite3_stmt* stmt_, std::vector<std::string> names_, const int n_max_,
                                 const std::vector<SEXPTYPE>& types_)
  : stmt(stmt_),
    n_max(n_max_),
    i(0),
    n(init_n()),
    names(names_)
{
  std::vector<std::pair<SEXPTYPE, int> > args;
  std::transform(types_.begin(), types_.end(), std::back_inserter(args), std::bind2nd(std::ptr_fun(&std::make_pair<SEXPTYPE, int>), 0));
  for (size_t j = 0; j < args.size(); ++j)
    args[j].second = j;
  std::transform(args.begin(), args.end(), std::back_inserter(data), &SqliteColumn::as);
}

SqliteDataFrame::~SqliteDataFrame() {
}

int SqliteDataFrame::init_n() const {
  if (n_max >= 0)
    return n_max;

  return 100;
}

bool SqliteDataFrame::set_col_values() {
  if (i >= n) {
    if (n_max >= 0)
      return false;

    n *= 2;
    resize();
  }

  for (size_t j = 0; j < data.size(); ++j) {
    data[j].set_col_value(stmt, n);
  }

  return true;
}

void SqliteDataFrame::advance() {
  ++i;

  if (i % 1000 == 0)
    checkUserInterrupt();
}

List SqliteDataFrame::get_data(std::vector<SEXPTYPE>& types_) {
  // Trim back to what we actually used
  finalize_cols();

  types_.clear();
  std::transform(data.begin(), data.end(), std::back_inserter(types_), std::mem_fun_ref(&SqliteColumn::get_type));

  List out(data.begin(), data.end());
  out.attr("names") = names;
  out.attr("class") = "data.frame";
  out.attr("row.names") = IntegerVector::create(NA_INTEGER, -n);
  return out;
}

void SqliteDataFrame::resize() {
  for (int j = 0; j < data.size(); ++j) {
    data[j].resize(n);
  }
}

void SqliteDataFrame::finalize_cols() {
  if (i < n) {
    n = i;
  }

  std::for_each(data.begin(), data.end(), boost::bind(&SqliteColumn::finalize, _1, stmt, i));
}
