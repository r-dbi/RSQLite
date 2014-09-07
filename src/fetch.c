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

void rsqlite_output_alloc(SEXP output, SQLiteFields *flds, int num_rec) {
  PROTECT(output);
  int p = flds->num_fields;

  for(int j = 0; j < p; j++){
    SET_VECTOR_ELT(output, j, allocVector(flds->Sclass[j], num_rec));
  }

  SEXP names = PROTECT(allocVector(STRSXP, p));
  SET_NAMES(output, names);
  UNPROTECT(1);
  for(int j = 0; j < p; j++){
    SET_STRING_ELT(names, j, mkChar(flds->name[j]));
  }
  
  UNPROTECT(1);
  return;
}

void rsqlite_output_expand(SEXP output, SQLiteFields *flds, int num_rec) {
  PROTECT(output);
  int p = flds->num_fields;

  for(int j = 0; j < p; j++){
    /* Note that in R-1.2.3 (at least) we need to protect SET_LENGTH */
    SEXP s_tmp = VECTOR_ELT(output, j);
    PROTECT(SET_LENGTH(s_tmp, num_rec));  
    SET_VECTOR_ELT(output, j, s_tmp);
    UNPROTECT(1);
  }
  UNPROTECT(1);
}

// Combines error text with error message from database, and frees result set
void exec_error(SQLiteConnection *con, const char *msg) {
  const char *db_msg = "";
  const char *sep = "";

  sqlite3 *db = con->drvConnection;
  int errcode = db ? sqlite3_errcode(db) : -1;
  if (errcode != SQLITE_OK) {
    db_msg = sqlite3_errmsg(db);
    sep = ": ";
  }
  char buf[2048];
  snprintf(buf, sizeof(buf), "%s%s%s", msg, sep, db_msg);
  
  rsqlite_exception_set(con, errcode, buf);
  rsqlite_result_free(con);

  error(buf);
}

static void
select_prepared_query(sqlite3_stmt *db_statement,
                      SEXP bind_data,
                      int bind_count,
                      int rows,
                      SQLiteConnection *con)
{
    char bindingErrorMsg[2048]; bindingErrorMsg[0] = '\0';
    RS_SQLite_bindParams *params =
        RS_SQLite_createParameterBinding(bind_count, bind_data,
                                         db_statement, bindingErrorMsg);
    if (params == NULL) {
        /* FIXME: this UNPROTECT is ugly, paired to caller */
        UNPROTECT(1);
        exec_error(con, bindingErrorMsg);
    }
    con->resultSet->drvData = params;
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
                          SQLiteConnection *con)
{
    int state, i;
    char bindingErrorMsg[2048]; bindingErrorMsg[0] = '\0';
    RS_SQLite_bindParams *params =
        RS_SQLite_createParameterBinding(bind_count, bind_data,
                                         db_statement, bindingErrorMsg);
    if (params == NULL) {
        /* FIXME: this UNPROTECT is ugly, paired to caller */
        UNPROTECT(1);
        exec_error(con, bindingErrorMsg);
    }

    /* we need to step through the query for each row */
    for (i=0; i<rows; i++) {
        state = bind_params_to_stmt(params, db_statement, i);
        if (state != SQLITE_OK) {
            UNPROTECT(1);
            exec_error(con, "rsqlite_query_send: could not bind data");
        }
        state = sqlite3_step(db_statement);
        if (state != SQLITE_DONE) {
            UNPROTECT(1);
            exec_error(con, "rsqlite_query_send: could not execute");
        }
        state = sqlite3_reset(db_statement);
        sqlite3_clear_bindings(db_statement);
        if (state != SQLITE_OK) {
            UNPROTECT(1);
            exec_error(con, "rsqlite_query_send: could not reset statement");
        }
    }
    RS_SQLite_freeParameterBinding(&params);
}


SEXP rsqlite_query_send(SEXP handle, SEXP statement, SEXP bind_data) {
  SQLiteConnection *con = get_connection(handle);
  sqlite3 *db_connection = con->drvConnection;
  sqlite3_stmt *db_statement = NULL;
  int state, bind_count;
  int rows = 0, cols = 0;

  if (con->resultSet) {
    if (con->resultSet->completed != 1) 
      warning("Closing result set with pending rows");
    rsqlite_result_free(con);
  }
  rsqlite_result_alloc(con);
  SQLiteResult* res = con->resultSet;

  /* allocate and init a new result set */
  res->completed = 0;
  char *dyn_statement = RS_DBI_copyString(CHAR(asChar(statement)));
  res->statement = dyn_statement;
  res->drvResultSet = db_statement;
  state = sqlite3_prepare_v2(db_connection, dyn_statement, -1,
    &db_statement, NULL);
  
  if (state != SQLITE_OK) {
    exec_error(con, "error in statement");
  }
  if (db_statement == NULL) {
    exec_error(con, "nothing to execute");
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
  rsqlite_exception_set(con, state, "OK");

  if (res->isSelect) {
    if (bind_count > 0) {
      select_prepared_query(db_statement, bind_data, bind_count, rows, con);
    }
  } else {
    if (bind_count > 0) {
      non_select_prepared_query(db_statement, bind_data, bind_count, rows, con);
    } else {
      state = sqlite3_step(db_statement);
      if (state != SQLITE_DONE) {
        exec_error(con, "rsqlite_query_send: could not execute1");
      }
    }
    res->completed = 1;
    res->rowsAffected = sqlite3_changes(db_connection);
  }
  
  return handle;
}

/* Fills the output VECSXP with one row of data from the resultset
 */
void fill_one_row(sqlite3_stmt *db_statement, SEXP output, int row_idx,
                  SQLiteFields *flds) {
  
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

static int do_select_step(SQLiteResult *res, int row_idx) {
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
SEXP rsqlite_query_fetch(SEXP handle, SEXP max_rec) {
  SQLiteResult* res = rsqlite_result_from_handle(handle);
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
    error("rsqlite_query_fetch: failed first step: %s",
      sqlite3_errmsg(sqlite3_db_handle(db_statement)));
  }
  
  SQLiteFields* flds = rsqlite_result_fields(res);

  int num_fields = flds->num_fields;
  int num_rec = asInteger(max_rec);
  int expand = (num_rec < 0);   /* dyn expand output to accommodate all rows*/
  if (expand || num_rec == 0) {
    num_rec = getDriver()->fetch_default_rec;
  }

  SEXP output = PROTECT(NEW_LIST(num_fields));
  rsqlite_output_alloc(output, flds, num_rec);
  while (state != SQLITE_DONE) {
    fill_one_row(db_statement, output, row_idx, flds);
    row_idx++;
    if (row_idx == num_rec) {  /* request satisfied or exhausted allocated space */
      if (expand) {    /* do we extend or return the records fetched so far*/
        num_rec = 1.5 * num_rec;
        rsqlite_output_expand(output, flds, num_rec);
      } else {
        break;       /* okay, no more fetching for now */
      }            
    }
    state = do_select_step(res, row_idx);
    if (state != SQLITE_ROW && state != SQLITE_DONE) {
      error("rsqlite_query_fetch: failed: %s", 
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

