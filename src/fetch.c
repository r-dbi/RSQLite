/* 
 * Copyright (C) 1999-2002 The Omega Project for Statistical Computing
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include "rsqlite.h"

RS_DBI_fields *
RS_DBI_allocFields(int num_fields)
{
  RS_DBI_fields *flds;
  size_t n;

  flds = (RS_DBI_fields *)malloc(sizeof(RS_DBI_fields));
  if(!flds){
    error("could not malloc RS_DBI_fields");
  }
  n = (size_t) num_fields;
  flds->num_fields = num_fields;
  flds->name =     (char **) calloc(n, sizeof(char *));
  flds->type =     (int *) calloc(n, sizeof(int));
  flds->length =   (int *) calloc(n, sizeof(int));
  flds->isVarLength = (int *) calloc(n, sizeof(int));
  flds->Sclass =   (SEXPTYPE *) calloc(n, sizeof(SEXPTYPE));

  return flds;
}

void
RS_DBI_freeFields(RS_DBI_fields *flds)
{
  if(flds->name) free(flds->name);
  if(flds->type) free(flds->type);
  if(flds->length) free(flds->length);
  if(flds->isVarLength) free(flds->isVarLength);
  if(flds->Sclass) free(flds->Sclass);
  free(flds);
  flds = (RS_DBI_fields *) NULL;
  return;
}

void
RS_DBI_allocOutput(SEXP output, RS_DBI_fields *flds,
  	   int num_rec, int  expand)
{
  SEXP names, s_tmp;
  int   j; 
  int    num_fields;
  SEXPTYPE  *fld_Sclass;

  PROTECT(output);

  num_fields = flds->num_fields;
  if(expand){
    for(j = 0; j < num_fields; j++){
      /* Note that in R-1.2.3 (at least) we need to protect SET_LENGTH */
      s_tmp = VECTOR_ELT(output, j);
      PROTECT(SET_LENGTH(s_tmp, num_rec));  
      SET_VECTOR_ELT(output, j, s_tmp);
      UNPROTECT(1);
    }
    UNPROTECT(1);
    return;
  }

  fld_Sclass = flds->Sclass;
  for(j = 0; j < num_fields; j++){
    switch((int)fld_Sclass[j]){
    case LGLSXP:    
      SET_VECTOR_ELT(output, j, NEW_LOGICAL(num_rec));
      break;
    case STRSXP:
      SET_VECTOR_ELT(output, j, NEW_CHARACTER(num_rec));
      break;
    case INTSXP:
      SET_VECTOR_ELT(output, j, NEW_INTEGER(num_rec));
      break;
    case REALSXP:
      SET_VECTOR_ELT(output, j, NEW_NUMERIC(num_rec));
      break;
    case RAWSXP:                /* falls through */
    case VECSXP:
      SET_VECTOR_ELT(output, j, NEW_LIST(num_rec));
      break;
    default:
      error("unsupported data type");
    }
  }

  PROTECT(names = NEW_CHARACTER(num_fields));
  for(j = 0; j< num_fields; j++){
    SET_STRING_ELT(names,j, mkChar(flds->name[j]));
  }
  SET_NAMES(output, names);
  UNPROTECT(2);
  return;
}



int RS_SQLite_get_row_count(sqlite3* db, const char* tname) {
    char* sqlQuery;
    const char* sqlFmt = "select rowid from %s order by rowid desc limit 1";
    int qrylen = strlen(sqlFmt);
    int rc = 0;
    int ans;
    sqlite3_stmt* stmt;
    const char* tail;

    qrylen += strlen(tname) + 1;
    sqlQuery = (char*)  R_alloc(qrylen, sizeof(char));
    snprintf(sqlQuery, qrylen, sqlFmt, tname);
    rc = sqlite3_prepare_v2(db, sqlQuery, -1, &stmt, &tail);
    if (rc != SQLITE_OK) {
        sqlite3_finalize(stmt);
        error("SQL error: %s\n", sqlite3_errmsg(db));
    }
    rc = sqlite3_step(stmt);
    if (rc != SQLITE_ROW && rc != SQLITE_DONE) {
        sqlite3_finalize(stmt);
        error("SQL error: %s\n", sqlite3_errmsg(db));
    }
    ans = sqlite3_column_int(stmt, 0);
    sqlite3_finalize(stmt);
    return ans;
}


SEXP RS_SQLite_quick_column(SEXP conHandle, SEXP table, SEXP column)
{
    SEXP ans = R_NilValue, rawv;
    RS_DBI_connection *con = RS_DBI_getConnection(conHandle);
    sqlite3 *db_connection = (sqlite3 *) con->drvConnection;
    sqlite3_stmt *stmt = NULL;
    int numrows, rc, i = 0, col_type, *intans = NULL, blob_len;
    char sqlQuery[500];
    const char *table_name = NULL, *column_name = NULL, *tail = NULL;
    double *doubleans = NULL;
    const Rbyte *blob_data;

    table_name = CHAR(STRING_ELT(table, 0));
    column_name = CHAR(STRING_ELT(column, 0));
    numrows = RS_SQLite_get_row_count(db_connection, table_name);
    snprintf(sqlQuery, sizeof(sqlQuery), "select %s from %s",
             column_name, table_name);

    rc = sqlite3_prepare_v2(db_connection, sqlQuery, strlen(sqlQuery), &stmt, &tail);
    /* FIXME: how should we be handling errors?
       Could either follow the pattern in the rest of the package or
       start to use the condition system and raise specific conditions.
    */
    if(rc != SQLITE_OK) {
        error("SQL error: %s\n", sqlite3_errmsg(db_connection));
    }

    rc = sqlite3_step(stmt);
    if (rc != SQLITE_ROW) {
        error("SQL error: %s\n", sqlite3_errmsg(db_connection));
    }
    col_type = sqlite3_column_type(stmt, 0);
    switch(col_type) {
    case SQLITE_INTEGER:
        PROTECT(ans = allocVector(INTSXP, numrows));
        intans = INTEGER(ans);
        break;
    case SQLITE_FLOAT:
        PROTECT(ans = allocVector(REALSXP, numrows));
        doubleans = REAL(ans);
        break;
    case SQLITE_TEXT:
        PROTECT(ans = allocVector(STRSXP, numrows));
        break;
    case SQLITE_NULL:
        error("RS_SQLite_quick_column: encountered NULL column");
        break;
    case SQLITE_BLOB:
        PROTECT(ans = allocVector(VECSXP, numrows));
        break;
    default:
        error("RS_SQLite_quick_column: unknown column type %d", col_type);
    }

    i = 0;
    while (rc == SQLITE_ROW && i < numrows) {
        switch (col_type) {
        case SQLITE_INTEGER:
            intans[i] = sqlite3_column_int(stmt, 0);
            break;
        case SQLITE_FLOAT:
            doubleans[i] = sqlite3_column_double(stmt, 0);
            break;
        case SQLITE_TEXT:
            SET_STRING_ELT(ans, i, /* cast for -Wall */
                           mkChar((char*)sqlite3_column_text(stmt, 0)));
            break;
        case SQLITE_BLOB:
            blob_data = (const Rbyte *) sqlite3_column_blob(stmt, 0);
            blob_len = sqlite3_column_bytes(stmt, 0);
            PROTECT(rawv = allocVector(RAWSXP, blob_len));
            memcpy(RAW(rawv), blob_data, blob_len * sizeof(Rbyte));;
            SET_VECTOR_ELT(ans, i, rawv);
            UNPROTECT(1);
            break;
        }
        i++;
        rc = sqlite3_step(stmt);
    }
    sqlite3_finalize(stmt);
    UNPROTECT(1);
    return ans;
}

void RSQLite_freeResultSet0(RS_DBI_resultSet *result, RS_DBI_connection *con)
{
    if (result->drvResultSet) {
        sqlite3_finalize((sqlite3_stmt *)result->drvResultSet);
        result->drvResultSet = NULL;
    }
    if (result->drvData) {
        RS_SQLite_bindParams *params = (RS_SQLite_bindParams *)result->drvData;
        R_ReleaseObject(params->data);
        RS_SQLite_freeParameterBinding(&params);
        result->drvData = NULL;
    }
    RS_DBI_freeResultSet0(result, con);
}

/* Helper function to clean up and report an error during a call to
   RS_SQLite_exec */
static void
exec_error(const char *msg,
           RS_DBI_connection *con,
           int bind_count,
           RS_SQLite_bindParams *params,
           SEXP rsHandle)
{
    sqlite3 *db = (sqlite3 *) con->drvConnection;
    int errcode = db ? sqlite3_errcode(db) : -1;
    char buf[2048];
    const char *db_msg = "";
    const char *sep = "";
    if (db && errcode != SQLITE_OK) {
        db_msg = sqlite3_errmsg(db);
        sep = ": ";
    }
    snprintf(buf, sizeof(buf), "%s%s%s", msg, sep, db_msg);
    setException(con, errcode, buf);
    if (rsHandle) {
        RSQLite_freeResultSet0(RS_DBI_getResultSet(rsHandle), con);
        rsHandle = NULL;
    }
    if (params) {
        RS_SQLite_freeParameterBinding(&params);
        params = NULL;
    }
    error(buf);
}

static void
select_prepared_query(sqlite3_stmt *db_statement,
                      SEXP bind_data,
                      int bind_count,
                      int rows,
                      RS_DBI_connection *con,
                      SEXP rsHandle)
{
    RS_DBI_resultSet *res;
    char bindingErrorMsg[2048]; bindingErrorMsg[0] = '\0';
    RS_SQLite_bindParams *params =
        RS_SQLite_createParameterBinding(bind_count, bind_data,
                                         db_statement, bindingErrorMsg);
    if (params == NULL) {
        /* FIXME: this UNPROTECT is ugly, paired to caller */
        UNPROTECT(1);
        exec_error(bindingErrorMsg, con, 0, NULL, rsHandle);
    }
    res = RS_DBI_getResultSet(rsHandle);
    res->drvData = params;
}

static int
bind_params_to_stmt(RS_SQLite_bindParams *params,
                    sqlite3_stmt *db_statement, int row)
{
    int state = SQLITE_OK, j;
    for (j = 0; j < params->count; j++) {
        SEXP pdata = VECTOR_ELT(params->data, j), v_elt;
        int integer;
        double number;
        Rbyte *raw;

        switch(TYPEOF(pdata)){
        case INTSXP:
            integer = INTEGER(pdata)[row];
            if (integer == NA_INTEGER)
                state = sqlite3_bind_null(db_statement, j+1);
            else
                state = sqlite3_bind_int(db_statement, j+1, integer);
            break;
        case REALSXP:
            number = REAL(pdata)[row];
            if (ISNA(number))
                state = sqlite3_bind_null(db_statement, j+1);
            else
                state = sqlite3_bind_double(db_statement, j+1, number);
            break;
        case VECSXP:            /* BLOB */
            v_elt = VECTOR_ELT(pdata, row);
            if (v_elt == R_NilValue) {
                state = sqlite3_bind_null(db_statement, j+1);
            } else {
                raw = RAW(v_elt);
                state = sqlite3_bind_blob(db_statement, j+1,
                                          raw, LENGTH(v_elt), SQLITE_STATIC);
            }
            break;
        case STRSXP:
            /* falls through */
        default:
            v_elt = STRING_ELT(pdata, row);
            if (NA_STRING == v_elt)
                state = sqlite3_bind_null(db_statement, j+1);
            else
                state = sqlite3_bind_text(db_statement, j+1,
                                          CHAR(v_elt), -1, SQLITE_STATIC);
            break;
        }
        if (state != SQLITE_OK) break;
    }
    return state;
}

static void
non_select_prepared_query(sqlite3_stmt *db_statement,
                          SEXP bind_data,
                          int bind_count,
                          int rows,
                          RS_DBI_connection *con,
                          SEXP rsHandle)
{
    int state, i;
    char bindingErrorMsg[2048]; bindingErrorMsg[0] = '\0';
    RS_SQLite_bindParams *params =
        RS_SQLite_createParameterBinding(bind_count, bind_data,
                                         db_statement, bindingErrorMsg);
    if (params == NULL) {
        /* FIXME: this UNPROTECT is ugly, paired to caller */
        UNPROTECT(1);
        exec_error(bindingErrorMsg, con, 0, NULL, rsHandle);
    }

    /* we need to step through the query for each row */
    for (i=0; i<rows; i++) {
        state = bind_params_to_stmt(params, db_statement, i);
        if (state != SQLITE_OK) {
            UNPROTECT(1);
            /* FIXME: add errmsg from sqlite */
            exec_error("RS_SQLite_exec: could not bind data",
                       con, 0, NULL, rsHandle);
        }
        state = sqlite3_step(db_statement);
        if (state != SQLITE_DONE) {
            UNPROTECT(1);
            /* FIXME: add errmsg from sqlite */
            exec_error("RS_SQLite_exec: could not execute",
                       con, 0, NULL, rsHandle);
        }
        state = sqlite3_reset(db_statement);
        sqlite3_clear_bindings(db_statement);
        if (state != SQLITE_OK) {
            UNPROTECT(1);
            exec_error("RS_SQLite_exec: could not reset statement",
                       con, 0, NULL, rsHandle);
        }
    }
    RS_SQLite_freeParameterBinding(&params);
}


SEXP RS_SQLite_exec(SEXP conHandle, SEXP statement, SEXP bind_data)
{
    RS_DBI_connection *con = RS_DBI_getConnection(conHandle);
    SEXP rsHandle;
    RS_DBI_resultSet *res;
    sqlite3 *db_connection = (sqlite3 *) con->drvConnection;
    sqlite3_stmt *db_statement = NULL;
    int state, bind_count;
    int rows = 0, cols = 0;
    char *dyn_statement = RS_DBI_copyString(CHAR(asChar(statement)));

    /* Do we have a pending resultSet in the current connection?
     * SQLite only allows  one resultSet per connection.
     */
    if (con->resultSet) {
        rsHandle = RS_DBI_asResHandle(conHandle);
        res = RS_DBI_getResultSet(rsHandle);
        if (res->completed != 1) {
            free(dyn_statement);
            error("connection with pending rows, close resultSet before continuing");
        } else
            RS_SQLite_closeResultSet(rsHandle);
    }

    /* allocate and init a new result set */
    PROTECT(rsHandle = RS_DBI_allocResultSet(conHandle));
    res = RS_DBI_getResultSet(rsHandle);
    res->completed = 0;
    res->statement = dyn_statement;
    res->drvResultSet = db_statement;
    state = sqlite3_prepare_v2(db_connection, dyn_statement, -1,
                               &db_statement, NULL);
    if (state != SQLITE_OK) {
        UNPROTECT(1);
        exec_error("error in statement", con, 0, NULL, rsHandle);
    }

    if (db_statement == NULL) {
        UNPROTECT(1);
        exec_error("nothing to execute", con, 0, NULL, rsHandle);
    }
    res->drvResultSet = (void *) db_statement;
    bind_count = sqlite3_bind_parameter_count(db_statement);
    if (bind_count > 0 && bind_data != R_NilValue) {
        rows = GET_LENGTH(GET_ROWNAMES(bind_data));
        cols = GET_LENGTH(bind_data);
    }


    res->isSelect = sqlite3_column_count(db_statement) > 0;
    res->rowCount = 0;      /* fake's cursor's row count */
    res->rowsAffected = -1; /* no rows affected */
    setException(con, state, "OK");

    if (res->isSelect) {
        if (bind_count > 0) {
            select_prepared_query(db_statement, bind_data, bind_count,
                                  rows, con, rsHandle);
        }
    } else {
        if (bind_count > 0) {
            non_select_prepared_query(db_statement, bind_data, bind_count,
                                      rows, con, rsHandle);
        }
        else {
            state = sqlite3_step(db_statement);
            if (state != SQLITE_DONE) {
                UNPROTECT(1);
                exec_error("RS_SQLite_exec: could not execute1",
                           con, 0, NULL, rsHandle);
            }
        }
        res->completed = 1;          /* BUG: what if query is async?*/
        res->rowsAffected = sqlite3_changes(db_connection);
    }
    UNPROTECT(1);
    return rsHandle;
}

RS_DBI_fields*
RS_SQLite_createDataMappings(SEXP rsHandle) {
  const char* col_decltype = NULL;

  RS_DBI_resultSet* result = RS_DBI_getResultSet(rsHandle);
  sqlite3_stmt* db_statement = (sqlite3_stmt *) result->drvResultSet;

  int ncol = sqlite3_column_count(db_statement);
  RS_DBI_fields* flds = RS_DBI_allocFields(ncol); /* BUG: mem leak if this fails? */
  flds->num_fields = ncol;

  for(int j = 0; j < ncol; j++){
    char* col_name = (char*) sqlite3_column_name(db_statement, j);
    if (col_name)
      flds->name[j] = RS_DBI_copyString(col_name);
    else { 
      // weird failure
      RS_DBI_freeFields(flds);
      flds = NULL;
      return NULL;
    }
    // We do our best to determine the type of the column.  When the first 
    // row retrieved contains a NULL and does not reference a table column, we 
    // give up.
    int col_type = sqlite3_column_type(db_statement, j);
    if (col_type == SQLITE_NULL) {
        /* try to get type from origin column */
        col_decltype = sqlite3_column_decltype(db_statement, j);
        col_type = SQLite_decltype_to_type(col_decltype);
    }
    switch(col_type) {
      case SQLITE_INTEGER:
        flds->type[j] = SQLITE_TYPE_INTEGER;
        flds->Sclass[j] = INTSXP;
        flds->length[j] = sizeof(int);
        flds->isVarLength[j] = 0;
        break;
      case SQLITE_FLOAT:
        flds->type[j] = SQLITE_TYPE_REAL;
        flds->Sclass[j] = REALSXP;
        flds->length[j] = sizeof(double);
        flds->isVarLength[j] = 0;
        break;
     case SQLITE_TEXT:
        flds->type[j] = SQLITE_TYPE_TEXT;
        flds->Sclass[j] = STRSXP;
        flds->length[j] = -1;   /* unknown */
        flds->isVarLength[j] = 1;
        break;
      case SQLITE_NULL:
        error("NULL column handling not implemented");
        break;
     case SQLITE_BLOB:
        flds->type[j] = SQLITE_TYPE_BLOB;
        flds->Sclass[j] = VECSXP;
        flds->length[j] = -1;   /* unknown */
        flds->isVarLength[j] = 1;
        break;
      default:
        error("unknown column type %d", col_type);
    }
  }
  return flds;
}


/* Fills the output VECSXP with one row of data from the resultset
 */
void fill_one_row(sqlite3_stmt *db_statement, SEXP output, int row_idx,
                  RS_DBI_fields *flds) {
  
  for (int j = 0; j < flds->num_fields; j++) {
    int is_null = (sqlite3_column_type(db_statement, j) == SQLITE_NULL);
    
    SEXP col = VECTOR_ELT(output, j);
    
    switch (flds->Sclass[j]) {
      case INTSXP:
        INTEGER(col)[row_idx] = is_null ? NA_INTEGER : 
          sqlite3_column_int(db_statement, j);
        break;
      case REALSXP:
        REAL(col)[row_idx] = is_null ? NA_REAL :
          sqlite3_column_double(db_statement, j);
        break;
      case VECSXP:            /* BLOB */
        if (is_null) continue;
        
        const Rbyte* blob_data = (const Rbyte *)sqlite3_column_blob(db_statement, j);
        int blob_len = sqlite3_column_bytes(db_statement, j);
        SEXP rawv = PROTECT(allocVector(RAWSXP, blob_len));
        memcpy(RAW(rawv), blob_data, blob_len * sizeof(Rbyte));
        SET_VECTOR_ELT(col, row_idx, rawv);
        UNPROTECT(1);
        break;
      case STRSXP:
        /* falls through */
      default:
        SET_STRING_ELT(col, row_idx, is_null ? NA_STRING : 
          mkChar((char*) sqlite3_column_text(db_statement, j)));
        break;
    }
  }
}

static int do_select_step(RS_DBI_resultSet *res, int row_idx)
{
    int state;
    RS_SQLite_bindParams * params = NULL;
    sqlite3_stmt *stmt = (sqlite3_stmt *)res->drvResultSet;
    if (res->drvData) {         /* we have parameters to bind */
        params = (RS_SQLite_bindParams *)res->drvData;
        if (params->row_complete) {
            params->row_complete = 0;
            sqlite3_clear_bindings(stmt);
            state = bind_params_to_stmt(params,
                                        stmt,
                                        params->rows_used);
            if (state != SQLITE_OK) return state;
            params->rows_used++;
        }
    }
    state = sqlite3_step(stmt);
    if (params && state == SQLITE_DONE) {
        params->row_complete = 1;
        if (params->rows_used < params->row_count) {
            state = sqlite3_reset(stmt);
            if (state != SQLITE_OK) return state;
            return do_select_step(res, row_idx);
        }
    }
    return state;
}

/* Return a data.frame containing the requested number of rows from
   the resultset.

   We try to determine the correct R type for each column in the
   result.  Currently, type detection happens only for the first fetch
   on a given resultset and the first row of the resultset is used for
   type interpolation.  If a NULL value appears in the first row of
   the resultset and the column corresponds to a DB table column, we
   guess the type based on the DB schema definition for the column.
   If the NULL value does not correspond to a table column, then we
   force character.
*/
SEXP RS_SQLite_fetch(SEXP rsHandle, SEXP max_rec) {
  RS_DBI_resultSet* res = RS_DBI_getResultSet(rsHandle);
  if (res->isSelect != 1) {
    warning("resultSet does not correspond to a SELECT statement");
    return R_NilValue;
  }
  if (res->completed == 1) {
    return R_NilValue;
  }

  /* We need to step once to be able to create the data mappings */
  int row_idx = 0;
  int state = do_select_step(res, row_idx);
  sqlite3_stmt* db_statement = (sqlite3_stmt *) res->drvResultSet;

  if (state != SQLITE_ROW && state != SQLITE_DONE) {
    error("RS_SQLite_fetch: failed first step: %s",
      sqlite3_errmsg(sqlite3_db_handle(db_statement)));
  }
  
  // Cache field mappings
  if (!res->fields) {
    res->fields = RS_SQLite_createDataMappings(rsHandle);
    if (!res->fields) {
      error("corrupt SQLite resultSet, missing fieldDescription");
    }
  }
  RS_DBI_fields* flds = res->fields;

  int num_fields = flds->num_fields;
  int num_rec = asInteger(max_rec);
  int expand = (num_rec < 0);   /* dyn expand output to accommodate all rows*/
  if (expand || num_rec == 0) {
    num_rec = getDriver()->fetch_default_rec;
  }

  SEXP output = PROTECT(NEW_LIST(num_fields));
  RS_DBI_allocOutput(output, flds, num_rec, 0);
  while (state != SQLITE_DONE) {
    fill_one_row(db_statement, output, row_idx, flds);
    row_idx++;
    if (row_idx == num_rec) {  /* request satisfied or exhausted allocated space */
      if (expand) {    /* do we extend or return the records fetched so far*/
        num_rec = 2 * num_rec;
        RS_DBI_allocOutput(output, flds, num_rec, expand);
      } else {
        break;       /* okay, no more fetching for now */
      }            
    }
    state = do_select_step(res, row_idx);
    if (state != SQLITE_ROW && state != SQLITE_DONE) {
      error("RS_SQLite_fetch: failed: %s", 
        sqlite3_errmsg(sqlite3_db_handle(db_statement)));
    }
  } /* end row loop */

  if (state == SQLITE_DONE) {
    res->completed = 1;
  }
  
  /* size to actual number of records fetched */
  if (row_idx < num_rec) {
    num_rec = row_idx;
    /* adjust the length of each of the members in the output_list */
    for (int j = 0; j<num_fields; j++) {
      SEXP s_tmp = VECTOR_ELT(output, j);
      PROTECT(SET_LENGTH(s_tmp, num_rec));
      SET_VECTOR_ELT(output, j, s_tmp);
      UNPROTECT(1);
    }
  }
  res->rowCount += num_rec;
  UNPROTECT(1);
  return output;
}

