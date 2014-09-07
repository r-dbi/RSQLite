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

#include "RS-DBI.h"
#include <R_ext/RS.h>

/* the invoking (freeing) function must provide a function for
 * freeing the conParams, and by setting the (*free_drvConParams)(void *)
 * pointer.
 */

void 
RS_DBI_freeConnection(SEXP conHandle)
{
  RS_DBI_connection *con;
  SQLiteDriver    *mgr;

  con = RS_DBI_getConnection(conHandle);
  mgr = getDriver();

  /* Are there open resultSets? If so, free them first */
  if(con->resultSet) {
    warning("opened resultSet(s) forcebly closed");
    RS_DBI_freeResultSet0(con->resultSet, con);
  }

  if(con->drvConnection) {
    char *errMsg = 
      "internal error in RS_DBI_freeConnection: driver might have left open its connection on the server";
    warning(errMsg);
  }
  if(con->exception){
    char *errMsg = 
      "internal error in RS_DBI_freeConnection: non-freed con->exception (some memory leaked)";
    warning(errMsg);
  }

  /* update the manager's connection table */
  mgr->num_con = 0;

  free(con);
  con = (RS_DBI_connection *) NULL;
  R_ClearExternalPtr(conHandle);
}

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

void
RS_DBI_freeResultSet(SEXP rsHandle)
{
  RS_DBI_freeResultSet0(RS_DBI_getResultSet(rsHandle),
                        RS_DBI_getConnection(rsHandle));
}

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
      s_tmp = LST_EL(output,j);
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
    SET_CHR_EL(names,j, mkChar(flds->name[j]));
  }
  SET_NAMES(output, names);
  UNPROTECT(2);
  return;
}

/* wrapper to strcpy */
char *
RS_DBI_copyString(const char *str)
{
  char *buffer;

  buffer = (char *) malloc((size_t) strlen(str)+1);
  if(!buffer)
    error("internal error in RS_DBI_copyString: could not alloc string space");
  return strcpy(buffer, str);
}


SEXP 
RS_DBI_createNamedList(char **names, SEXPTYPE *types, int *lengths, int  n)
{
  SEXP output, output_names, obj = R_NilValue;
  int  num_elem;
  int   j;

  PROTECT(output = NEW_LIST(n));
  PROTECT(output_names = NEW_CHARACTER(n));
  for(j = 0; j < n; j++){
    num_elem = lengths[j];
    switch((int)types[j]){
    case LGLSXP: 
      PROTECT(obj = NEW_LOGICAL(num_elem));
      break;
    case INTSXP:
      PROTECT(obj = NEW_INTEGER(num_elem));
      break;
    case REALSXP:
      PROTECT(obj = NEW_NUMERIC(num_elem));
      break;
    case STRSXP:
      PROTECT(obj = NEW_CHARACTER(num_elem));
      break;
    case RAWSXP:                /* falls through */
    case VECSXP:
      PROTECT(obj = NEW_LIST(num_elem));
      break;
    default:
      error("unsupported data type");
    }
    SET_VECTOR_ELT(output, (int)j, obj);
    SET_CHR_EL(output_names, j, mkChar(names[j]));
  }
  SET_NAMES(output, output_names);
  UNPROTECT(n+2);
  return(output);
}

SEXP 
RS_DBI_SclassNames(SEXP type)
{
  SEXP typeNames;
  int *typeCodes;
  int n;
  int  i;
  
  if(type==R_NilValue)
     error("internal error in RS_DBI_SclassNames: input S types must be nonNULL");
  n = LENGTH(type);
  typeCodes = INTEGER_DATA(type);
  PROTECT(typeNames = NEW_CHARACTER(n));
  for(i = 0; i < n; i++) {
    const char* s = type2char(typeCodes[i]);
    SET_CHR_EL(typeNames, i, mkChar(s));
  }
  UNPROTECT(1);
  return typeNames;
}

/* FIXME: need to address this fwd declaration */
SEXP
RS_SQLite_closeConnection(SEXP conHandle);

static void _finalize_con_handle(SEXP xp)
{
    if (R_ExternalPtrAddr(xp)) {
        RS_SQLite_closeConnection(xp);
        R_ClearExternalPtr(xp);
    }
}

SEXP
RS_DBI_asConHandle(RS_DBI_connection *con)
{
    SEXP conHandle, s_ids, label;
    int *ids;
    PROTECT(s_ids = allocVector(INTSXP, 2));
    ids = INTEGER(s_ids);
    ids[0] = 0;
    ids[1] = 0;
    PROTECT(label = mkString("DBI CON"));
    conHandle = R_MakeExternalPtr(con, label, s_ids);
    UNPROTECT(2);
    R_RegisterCFinalizerEx(conHandle, _finalize_con_handle, 1);
    return conHandle;
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

RS_DBI_connection *
RS_DBI_getConnection(SEXP conHandle)
{
    RS_DBI_connection *con = (RS_DBI_connection *)R_ExternalPtrAddr(conHandle);
    if (!con) error("expired SQLiteConnection");
    return con;
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

SEXP     /* named list */
RS_DBI_getFieldDescriptions(RS_DBI_fields *flds)
{
  int n = 4;
  char  *desc[] = {"name", "Sclass", "type", "len"};
  SEXPTYPE types[] = {STRSXP, INTSXP,   INTSXP, INTSXP};
  int lengths[n];
  int num_fields = flds->num_fields;
  for (int j = 0; j < n; j++) 
    lengths[j] = num_fields;
  
  SEXP S_fields = PROTECT(RS_DBI_createNamedList(desc, types, lengths, n));
  for (int i = 0; i < num_fields; i++) {
    SET_LST_CHR_EL(S_fields,0,i,mkChar(flds->name[i]));
    LST_INT_EL(S_fields,1,i) = flds->Sclass[i];
    LST_INT_EL(S_fields,2,i) = flds->type[i];
    LST_INT_EL(S_fields,3,i) = flds->length[i];
  }
  UNPROTECT(1);
  
  return S_fields;
}
