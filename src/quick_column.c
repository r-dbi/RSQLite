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
  SQLiteConnection *con = get_connection(conHandle);
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
