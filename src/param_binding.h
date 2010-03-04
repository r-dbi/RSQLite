#ifndef PARAM_BINDING_H_
#define PARAM_BINDING_H_

#include <Rinternals.h>
#include "sqlite.h"

typedef struct st_sqlite_bindparam {
    SEXPTYPE type;
    SEXP data;
    int is_protected;
} RS_SQLite_bindParam;


RS_SQLite_bindParam *RS_SQLite_createParameterBinding(int n,
                                                      SEXP bind_data, sqlite3_stmt *stmt,
                                                      char *errorMsg);
void RS_SQLite_freeParameterBinding(int n,
                                    RS_SQLite_bindParam *param);

#endif  /* PARAM_BINDING_H_ */
