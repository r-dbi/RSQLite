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
    RS_SQLite_bindParams *params = result->drvData;
    R_ReleaseObject(params->data);
    RS_SQLite_freeParameterBinding(&params);
    result->drvData = NULL;
  }
  
  if (result->statement)
    free(result->statement);
  if (result->fields)
    RS_DBI_freeFields(result->fields);
  
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


SEXP fieldInfo(RS_DBI_fields *flds) {
  int n = flds ? flds->num_fields : 0;

  SEXP info = PROTECT(allocVector(VECSXP, 4));
  SEXP info_nms = PROTECT(allocVector(STRSXP, 4));
  SET_NAMES(info, info_nms);
  UNPROTECT(1);

  int i = 0;
  SET_STRING_ELT(info_nms, i, mkChar("name"));
  SEXP names = PROTECT(allocVector(STRSXP, n));
  for (int j = 0; j < n; j++) {
    SET_STRING_ELT(names, j, mkChar(flds->name[j]));
  }
  SET_VECTOR_ELT(info, i++, names);
  UNPROTECT(1);

  SET_STRING_ELT(info_nms, i, mkChar("Sclass"));
  SEXP sclass = PROTECT(allocVector(STRSXP, n));
  for (int j = 0; j < n; j++) {
    const char* type = type2char(flds->Sclass[j]);
    SET_STRING_ELT(sclass, j, mkChar(type));
  }
  SET_VECTOR_ELT(info, i++, sclass);
  UNPROTECT(1);
  
  SET_STRING_ELT(info_nms, i, mkChar("type"));
  SEXP types = PROTECT(allocVector(STRSXP, n));
  for (int j = 0; j < n; j++) {
    char* type = field_type(flds->type[j]);
    SET_STRING_ELT(types, j, mkChar(type));
  }
  SET_VECTOR_ELT(info, i++, types);
  UNPROTECT(1);
  
  SET_STRING_ELT(info_nms, i, mkChar("len"));
  SEXP lens = PROTECT(allocVector(INTSXP, n));
  for (int j = 0; j < n; j++) {
    INTEGER(lens)[j] = flds->length[j];
  }
  SET_VECTOR_ELT(info, i++, lens);
  UNPROTECT(1);


  UNPROTECT(1);
  return info;
}


SEXP resultSetInfo(SEXP handle) {
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
  SEXP fields = PROTECT(fieldInfo(result->fields));
  SET_VECTOR_ELT(info, i++, fields);
  UNPROTECT(1);

  UNPROTECT(1);
  return info;
}
