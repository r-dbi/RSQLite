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


SEXP
RS_DBI_allocResultSet(SEXP conHandle)
{
  RS_DBI_connection *con = NULL;
  RS_DBI_resultSet  *result = NULL;

  con = RS_DBI_getConnection(conHandle);

  result = (RS_DBI_resultSet *) malloc(sizeof(RS_DBI_resultSet));
  if (!result){
    char *errMsg = "could not malloc dbResultSet";
    error(errMsg);
  }
  result->drvResultSet = (void *) NULL; /* driver's own resultSet (cursor)*/
  result->drvData = (void *) NULL;   /* this can be used by driver*/
  result->statement = (char *) NULL;
  result->isSelect = -1;
  result->rowsAffected = -1;
  result->rowCount = 0;
  result->completed = -1;
  result->fields = (RS_DBI_fields *) NULL;
  
  /* update connection's resultSet table */
  con->resultSet = result;

  return RS_DBI_asResHandle(conHandle);
}

void RS_DBI_freeResultSet0(RS_DBI_resultSet *result, RS_DBI_connection *con)
{
    if(result->drvResultSet) {
      warning("freeResultSet failed (result->drvResultSet)");
    }
    if (result->drvData) {
      warning("freeResultSet failed (result->drvData)");
    }
    if (result->statement)
      free(result->statement);
    if (result->fields)
      RS_DBI_freeFields(result->fields);
    free(result);
    
    result = (RS_DBI_resultSet *) NULL;
    con->resultSet = NULL;
}


SEXP
DBI_newResultHandle(SEXP xp, SEXP resId)
{
    return RS_DBI_asResHandle(xp);
}

SEXP
RS_DBI_asResHandle(SEXP conxp)
{
    SEXP resHandle, s_ids, label, v;
    int *ids;
    PROTECT(s_ids = allocVector(INTSXP, 3));
    ids = INTEGER(s_ids);
    ids[0] = 0;
    ids[1] = 0;
    ids[2] = 0;
    PROTECT(v = allocVector(VECSXP, 2));
    SET_VECTOR_ELT(v, 0, s_ids);
    /* this ensures the connection is preserved as long as
       there is a reference to a result set
     */
    SET_VECTOR_ELT(v, 1, conxp);
    PROTECT(label = mkString("DBI RES"));
    resHandle = R_MakeExternalPtr(R_ExternalPtrAddr(conxp), label, v);
    UNPROTECT(3);
    /* FIXME: add finalizer code */
    return resHandle;
}


RS_DBI_resultSet *
RS_DBI_getResultSet(SEXP rsHandle)
{
  RS_DBI_connection *con;
  con = RS_DBI_getConnection(rsHandle);
  if(!con)
    error("internal error in RS_DBI_getResultSet: bad connection");
  return con->resultSet;
}


void RSQLite_closeResultSet0(RS_DBI_resultSet *result, RS_DBI_connection *con)
{
   if(result->drvResultSet == NULL)
       error("corrupt SQLite resultSet, missing statement handle");
    RSQLite_freeResultSet0(result, con);
}

SEXP 
RS_SQLite_closeResultSet(SEXP resHandle)
{
    RSQLite_closeResultSet0(RS_DBI_getResultSet(resHandle),
                            RS_DBI_getConnection(resHandle));
    /* The connection external ptr is stored within the result handle
       so that an active result keeps the connection protected.  When
       we close the result set, we remove the reference to the
       connection so that the connection can be gc'd.
     */
    SET_VECTOR_ELT(R_ExternalPtrProtected(resHandle), 1, R_NilValue);
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


SEXP resultSetInfo(SEXP rsHandle) {
  RS_DBI_resultSet* result = RS_DBI_getResultSet(rsHandle);

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

SEXP isValidResult(SEXP dbObj) {
  RS_DBI_resultSet *res = R_ExternalPtrAddr(dbObj);

  if (!res) return ScalarLogical(0);

  return ScalarLogical(1);
}
