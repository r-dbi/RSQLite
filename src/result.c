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

void rsqlite_result_alloc(SQLiteConnection* con) {
  SQLiteResult* result = malloc(sizeof(SQLiteResult));
  if (!result) {
    error("could not malloc dbResultSet");
  }
  result->drvResultSet = NULL; 
  result->drvData = NULL; 
  result->statement = NULL;
  result->isSelect = -1;
  result->rowsAffected = -1;
  result->rowCount = 0;
  result->completed = -1;
  result->fields = NULL;
  
  con->resultSet = result;
}

void rsqlite_result_free(SQLiteConnection* con) {
  SQLiteResult* result = con->resultSet;
    
  if (result->drvResultSet) {
    sqlite3_finalize(result->drvResultSet);
    result->drvResultSet = NULL;
  }
  if (result->drvData) {
    RSQLiteParams *params = result->drvData;
    R_ReleaseObject(params->data);
    RS_SQLite_freeParameterBinding(&params);
    result->drvData = NULL;
  }
  
  if (result->statement)
    free(result->statement);
  if (result->fields)
    rsqlite_fields_free(result->fields);
  
  free(result);
  
  con->resultSet = NULL;
}

SEXP rsqlite_result_free_handle(SEXP handle) {
  SQLiteConnection* con = get_connection(handle);
  rsqlite_result_free(con);
  
  return ScalarLogical(1);
}


SQLiteResult* rsqlite_result_from_handle(SEXP handle) {
  SQLiteConnection* con = get_connection(handle);
  
  if (!con->resultSet) {
    error("Invalid result");
  }
  
  return con->resultSet;
}

SEXP rsqlite_result_valid(SEXP handle) {
  SQLiteConnection *con = get_connection(handle);
  if (!con->resultSet)
    return ScalarLogical(0);

  return ScalarLogical(1);
}

SEXP rsqlite_result_info(SEXP handle) {
  SQLiteResult* result = rsqlite_result_from_handle(handle);

  SEXP info = PROTECT(allocVector(VECSXP, 6));
  SEXP info_nms = PROTECT(allocVector(STRSXP, 6));
  SET_NAMES(info, info_nms);
  UNPROTECT(1);

  int i = 0;
  SET_STRING_ELT(info_nms, i, mkChar("statement"));
  SET_VECTOR_ELT(info, i++, mkString(result->statement));

  SET_STRING_ELT(info_nms, i, mkChar("isSelect"));
  SET_VECTOR_ELT(info, i++, ScalarInteger(result->isSelect));

  SET_STRING_ELT(info_nms, i, mkChar("rowsAffected"));
  SET_VECTOR_ELT(info, i++, ScalarInteger(result->rowsAffected));

  SET_STRING_ELT(info_nms, i, mkChar("rowCount"));
  SET_VECTOR_ELT(info, i++, ScalarInteger(result->rowCount));

  SET_STRING_ELT(info_nms, i, mkChar("completed"));
  SET_VECTOR_ELT(info, i++, ScalarInteger(result->completed));
  
  SET_STRING_ELT(info_nms, i, mkChar("fields"));
  SEXP fields = PROTECT(rsqlite_field_info(result->fields));
  SET_VECTOR_ELT(info, i++, fields);
  UNPROTECT(1);

  UNPROTECT(1);
  return info;
}

SQLiteFields* rsqlite_result_fields(SQLiteResult* result) {
  // Already computed, return cached result
  if (result->fields) 
    return result->fields;
  
  sqlite3_stmt* db_statement = (sqlite3_stmt *) result->drvResultSet;

  int ncol = sqlite3_column_count(db_statement);
  SQLiteFields* flds = rsqlite_fields_alloc(ncol);

  for(int j = 0; j < ncol; j++){
    char* col_name = (char*) sqlite3_column_name(db_statement, j);
    if (col_name) {
      flds->name[j] = RS_DBI_copyString(col_name);
    } else { 
      // weird failure
      rsqlite_fields_free(flds);
      flds = NULL;
      return NULL;
    }
    // We do our best to determine the type of the column. If the first row 
    // retrieved contains a NULL and does not reference a table column, we 
    // give up.
    int col_type = sqlite3_column_type(db_statement, j);
    if (col_type == SQLITE_NULL) {
        /* try to get type from origin column */
        const char* col_decltype = sqlite3_column_decltype(db_statement, j);
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
     case SQLITE_BLOB:
        flds->type[j] = SQLITE_TYPE_BLOB;
        flds->Sclass[j] = VECSXP;
        flds->length[j] = -1;   /* unknown */
        flds->isVarLength[j] = 1;
        break;
      case SQLITE_NULL:
        error("NULL column handling not implemented");
        break;
      default:
        error("unknown column type %d", col_type);
    }
  }
  result->fields = flds;
  return flds;
}
