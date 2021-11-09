#define STRICT_R_HEADERS
#define R_NO_REMAP
#include <cpp11/R.hpp>

#include "pch.h"
#include "DbConnection.h"


[[cpp11::register]]
void extension_load(Rcpp::XPtr<DbConnectionPtr> con, const std::string& file, const std::string& entry_point) {
  char* zErrMsg = NULL;
  int rc = sqlite3_load_extension((*con)->conn(), file.c_str(), entry_point.c_str(), &zErrMsg);
  if (rc != SQLITE_OK) {
    std::string err_msg = zErrMsg;
    sqlite3_free(zErrMsg);
    cpp11::stop("Failed to load extension: %s", err_msg.c_str());
  }
}
