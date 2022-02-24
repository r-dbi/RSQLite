#include "pch.h"
#include "DbConnection.h"

attribute_visible int sqlite3_extension_init(
    sqlite3 *db,
    char **pzErrMsg,
    const sqlite3_api_routines *pApi
);

attribute_visible int sqlite3_regexp_init(
    sqlite3 *db,
    char **pzErrMsg,
    const sqlite3_api_routines *pApi
);

attribute_visible int sqlite3_series_init(
    sqlite3 *db,
    char **pzErrMsg,
    const sqlite3_api_routines *pApi
);

attribute_visible int sqlite3_csv_init(
    sqlite3 *db,
    char **pzErrMsg,
    const sqlite3_api_routines *pApi
);



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
