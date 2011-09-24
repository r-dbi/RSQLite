#ifndef PARAM_BINDING_H_
#define PARAM_BINDING_H_

#include <Rinternals.h>
#include "sqlite.h"

typedef struct st_sqlite_bindparams {
    int count;
    int row_count;
    int rows_used;
    int row_complete;
    SEXP data;
} RS_SQLite_bindParams;


RS_SQLite_bindParams *
RS_SQLite_createParameterBinding(int n,
                                 SEXP bind_data, sqlite3_stmt *stmt,
                                 char *errorMsg);

void RS_SQLite_freeParameterBinding(RS_SQLite_bindParams **);

#endif  /* PARAM_BINDING_H_ */
