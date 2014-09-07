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

  flds = malloc(sizeof(RS_DBI_fields));
  if(!flds){
    error("could not malloc RS_DBI_fields");
  }
  n = (size_t) num_fields;
  flds->num_fields = num_fields;
  flds->name =     calloc(n, sizeof(char *));
  flds->type =     calloc(n, sizeof(int));
  flds->length =   calloc(n, sizeof(int));
  flds->isVarLength = calloc(n, sizeof(int));
  flds->Sclass =   calloc(n, sizeof(SEXPTYPE));

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
  flds = NULL;
  return;
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

RS_DBI_fields*
RS_SQLite_createDataMappings(SEXP handle) {
  const char* col_decltype = NULL;

  SQLiteResult* result = rsqlite_result_from_handle(handle);
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
