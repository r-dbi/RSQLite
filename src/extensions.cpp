#include "pch.h"
#include "DbConnection.h"
#include "workarounds/XPtr.h"


// [[Rcpp::export]]
void extension_load(XPtr<DbConnectionPtr> con, const std::string& file, const std::string& entry_point) {
  char* zErrMsg = NULL;
  int rc = sqlite3_load_extension((*con)->conn(), file.c_str(), entry_point.c_str(), &zErrMsg);
  if (rc != SQLITE_OK) {
    std::string err_msg = zErrMsg;
    sqlite3_free(zErrMsg);
    stop("Failed to load extension: %s", err_msg.c_str());
  }
}
