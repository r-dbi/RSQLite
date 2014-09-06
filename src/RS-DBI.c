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

static RS_DBI_manager *dbManager = NULL;

static int HANDLE_LENGTH(SEXP handle)
{
    SEXP h = R_ExternalPtrProtected(handle);
    if (TYPEOF(h) == VECSXP) h = VECTOR_ELT(h, 0);
    return Rf_length(h);
}

Mgr_Handle
RS_DBI_allocManager(const char *drvName, int max_con,
		    int fetch_default_rec, int force_realloc)
{
  /* Currently, the dbManager is a singleton (therefore we don't 
   * completly free all the space).  Here we alloc space
   * for the dbManager and return its mgrHandle.  force_realloc
   * means to re-allocate number of connections, etc. (in this case
   * we require to have all connections closed).  (Note that if we
   * re-allocate, we don't re-set the counter, and thus we make sure
   * we don't recycle connection Ids in a giver S/R session).
   */
  Mgr_Handle mgrHandle;
  RS_DBI_manager *mgr;
  int counter;
  int mgr_id = getpid();
  int i;

  mgrHandle = RS_DBI_asMgrHandle(mgr_id);

  if(!dbManager){                      /* alloc for the first time */
    counter = 0;                       /* connections handled so far */
    mgr = (RS_DBI_manager*) malloc(sizeof(RS_DBI_manager));
  }
  else {                               /* we're re-entering */
    if(dbManager->connections){        /* and mgr is valid */
      if(!force_realloc)            
	return mgrHandle;
      else
	RS_DBI_freeManager(mgrHandle);  /* i.e., free connection arrays*/    
    }
    counter = dbManager->counter;
    mgr = dbManager;
  }
 /* Ok, we're here to expand number of connections, etc.*/
  if(!mgr)
    RS_DBI_errorMessage("could not malloc the dbManger", RS_DBI_ERROR);
  mgr->drvName = RS_DBI_copyString(drvName);
  mgr->drvData = (void *) NULL;
  mgr->managerId = mgr_id;
  mgr->connections =  (RS_DBI_connection **) 
    calloc((size_t) max_con, sizeof(RS_DBI_connection));
  if(!mgr->connections){
    free(mgr);
    RS_DBI_errorMessage("could not calloc RS_DBI_connections", RS_DBI_ERROR);
  }
  mgr->connectionIds = (int *) calloc((size_t)max_con, sizeof(int));
  if(!mgr->connectionIds){
    free(mgr->connections);
    free(mgr);
    RS_DBI_errorMessage("could not calloc vector of connection Ids",
          RS_DBI_ERROR);
  }
  mgr->counter = counter;
  mgr->length = max_con;
  mgr->num_con = 0;
  mgr->fetch_default_rec = fetch_default_rec;
  for(i=0; i < max_con; i++){
    mgr->connectionIds[i] = -1;
    mgr->connections[i] = (RS_DBI_connection *) NULL;
  }
  
  dbManager = mgr;

  return mgrHandle;
}

/* We don't want to completely free the dbManager, but rather we 
 * re-initialize all the fields except for mgr->counter to ensure we don't
 * re-cycle connection ids across R/S DBI sessions in the the same pid
 * (S/R session).
 */
void
RS_DBI_freeManager(Mgr_Handle mgrHandle)
{
  RS_DBI_manager *mgr;

  mgr = RS_DBI_getManager();
  if(mgr->num_con > 0){    
    char *errMsg = "all opened connections were forcebly closed";
    RS_DBI_errorMessage(errMsg, RS_DBI_WARNING);
  }
  if(mgr->drvData){
    char *errMsg = "mgr->drvData was not freed (some memory leaked)";
    RS_DBI_errorMessage(errMsg, RS_DBI_WARNING);
  }
  if(mgr->drvName){
    free(mgr->drvName);
    mgr->drvName = (char *) NULL;
  }
  if(mgr->connections) {
    free(mgr->connections);
    mgr->connections = (RS_DBI_connection **) NULL;
  }
  if(mgr->connectionIds) {
    free(mgr->connectionIds);
    mgr->connectionIds = (int *) NULL;
  }
  return;
}

Con_Handle
RS_DBI_allocConnection(Mgr_Handle mgrHandle, int max_res)
{
  RS_DBI_manager    *mgr;
  RS_DBI_connection *con;
  Con_Handle conHandle;
  int  i, con_id;
  
  mgr = RS_DBI_getManager();
  con = (RS_DBI_connection *) malloc(sizeof(RS_DBI_connection));
  if(!con){
    RS_DBI_errorMessage("could not malloc dbConnection", RS_DBI_ERROR);
  }
  con->managerId = MGR_ID(mgrHandle);
  con_id = mgr->counter;
  con->connectionId = con_id;
  con->drvConnection = (void *) NULL;
  con->drvData = (void *) NULL;    /* to be used by the driver in any way*/
  con->conParams = (void *) NULL;
  con->counter = 0;
  con->length = max_res;           /* length of resultSet vector */
  
  /* result sets for this connection */
  con->resultSets = (RS_DBI_resultSet **)
    calloc((size_t) max_res, sizeof(RS_DBI_resultSet));
  if(!con->resultSets){
    free(con);
    RS_DBI_errorMessage("could not calloc resultSets for the dbConnection",
                        RS_DBI_ERROR);
  }
  con->num_res = 0;
  con->resultSetIds = (int *) calloc((size_t) max_res, sizeof(int));
  if(!con->resultSetIds) {
    free(con->resultSets);
    free(con);
    RS_DBI_errorMessage("could not calloc vector of resultSet Ids",
                        RS_DBI_ERROR);
  }
  for(i=0; i<max_res; i++){
    con->resultSets[i] = (RS_DBI_resultSet *) NULL;
    con->resultSetIds[i] = -1;
  }

  /* Finally, update connection table in mgr */
  mgr->num_con += 1;
  mgr->counter += 1;
  conHandle = RS_DBI_asConHandle(MGR_ID(mgrHandle), con_id, con);
  return conHandle;
}

/* the invoking (freeing) function must provide a function for
 * freeing the conParams, and by setting the (*free_drvConParams)(void *)
 * pointer.
 */

void 
RS_DBI_freeConnection(SEXP conHandle)
{
  RS_DBI_connection *con;
  RS_DBI_manager    *mgr;

  con = RS_DBI_getConnection(conHandle);
  mgr = RS_DBI_getManager();

  /* Are there open resultSets? If so, free them first */
  if(con->num_res > 0) {
    char *errMsg = "opened resultSet(s) forcebly closed";
    int  i;
    for(i=0; i < con->num_res; i++){
        RS_DBI_freeResultSet0(con->resultSets[i], con);
    }
    RS_DBI_errorMessage(errMsg, RS_DBI_WARNING);
  }
  if(con->drvConnection) {
    char *errMsg = 
      "internal error in RS_DBI_freeConnection: driver might have left open its connection on the server";
    RS_DBI_errorMessage(errMsg, RS_DBI_WARNING);
  }
  if(con->conParams){
    char *errMsg =
      "internal error in RS_DBI_freeConnection: non-freed con->conParams (tiny memory leaked)";
    RS_DBI_errorMessage(errMsg, RS_DBI_WARNING);
  }
  if(con->drvData){
    char *errMsg = 
      "internal error in RS_DBI_freeConnection: non-freed con->drvData (some memory leaked)";
    RS_DBI_errorMessage(errMsg, RS_DBI_WARNING);
  }
  /* delete this connection from manager's connection table */
  if(con->resultSets) free(con->resultSets);
  if(con->resultSetIds) free(con->resultSetIds);

  /* update the manager's connection table */
  mgr->num_con -= 1;

  free(con);
  con = (RS_DBI_connection *) NULL;
  R_ClearExternalPtr(conHandle);
}

SEXP
RS_DBI_allocResultSet(SEXP conHandle)
{
  RS_DBI_connection *con = NULL;
  RS_DBI_resultSet  *result = NULL;
  int indx, res_id;

  con = RS_DBI_getConnection(conHandle);
  indx = RS_DBI_newEntry(con->resultSetIds, con->length);
  if(indx < 0){
    char msg[128], fmt[128];
    (void) strcpy(fmt, "cannot allocate a new resultSet -- ");
    (void) strcat(fmt, "maximum of %d resultSets already reached");
    (void) sprintf(msg, fmt, con->length);
    RS_DBI_errorMessage(msg, RS_DBI_ERROR);
  }

  result = (RS_DBI_resultSet *) malloc(sizeof(RS_DBI_resultSet));
  if(!result){
    char *errMsg = "could not malloc dbResultSet";
    RS_DBI_freeEntry(con->resultSetIds, indx);
    RS_DBI_errorMessage(errMsg, RS_DBI_ERROR);
  }
  result->drvResultSet = (void *) NULL; /* driver's own resultSet (cursor)*/
  result->drvData = (void *) NULL;   /* this can be used by driver*/
  result->statement = (char *) NULL;
  result->managerId = MGR_ID(conHandle);
  result->connectionId = CON_ID(conHandle);
  result->resultSetId = con->counter;
  result->isSelect = -1;
  result->rowsAffected = -1;
  result->rowCount = 0;
  result->completed = -1;
  result->fields = (RS_DBI_fields *) NULL;
  
  /* update connection's resultSet table */
  res_id = con->counter;
  con->num_res += 1;
  con->counter += 1;
  con->resultSets[indx] = result;
  con->resultSetIds[indx] = res_id;

  return RS_DBI_asResHandle(MGR_ID(conHandle), CON_ID(conHandle), res_id,
                            conHandle);
}

void RS_DBI_freeResultSet0(RS_DBI_resultSet *result, RS_DBI_connection *con)
{
    if(result->drvResultSet) {
        char *errMsg =
            "internal error in RS_DBI_freeResultSet: "
            "non-freed result->drvResultSet (some memory leaked)";
        RS_DBI_errorMessage(errMsg, RS_DBI_ERROR);
    }
    if (result->drvData) {
        char *errMsg =
            "internal error in RS_DBI_freeResultSet: "
            "non-freed result->drvData (some memory leaked)";
        RS_DBI_errorMessage(errMsg, RS_DBI_WARNING);
    }
    if (result->statement)
        free(result->statement);
    if (result->fields)
        RS_DBI_freeFields(result->fields);
    free(result);
    result = (RS_DBI_resultSet *) NULL;

    /* update connection's resultSet table */
    /* indx = RS_DBI_lookup(con->resultSetIds, con->length, RES_ID(rsHandle)); */
    /* SQLite connections only ever have one result set */
    RS_DBI_freeEntry(con->resultSetIds, 0);
    con->resultSets[0] = NULL;
    con->num_res -= 1;
}

void
RS_DBI_freeResultSet(Res_Handle rsHandle)
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
    char *errMsg = "could not malloc RS_DBI_fields";
    RS_DBI_errorMessage(errMsg, RS_DBI_ERROR);
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
      RS_DBI_errorMessage("unsupported data type", RS_DBI_ERROR);
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

SEXP  		/* boolean */
RS_DBI_validHandle(Db_Handle handle)
{ 
    SEXP valid, contents;
    int  handleType = 0;
    if (TYPEOF(handle) != EXTPTRSXP) return 0;
    contents = R_ExternalPtrProtected(handle);
    if (TYPEOF(contents) == VECSXP) {
        handleType = RES_HANDLE_TYPE;
    } else {
        switch(length(contents)) {
        case MGR_HANDLE_TYPE:
            handleType = MGR_HANDLE_TYPE;
            break;
        case CON_HANDLE_TYPE:
            handleType = CON_HANDLE_TYPE;
            break;
        case RES_HANDLE_TYPE:
            handleType = RES_HANDLE_TYPE;
            break;
        }
    }
    PROTECT(valid = NEW_LOGICAL(1));
    LGL_EL(valid,0) = is_validHandle(handle, handleType);
    UNPROTECT(1);
    return valid;
}

void 
RS_DBI_errorMessage(const char *msg, DBI_EXCEPTION exception_type)
{
  char *driver = "RS-DBI";   /* TODO: use the actual driver name */
  
  switch(exception_type) {
  case RS_DBI_MESSAGE:
    PROBLEM "%s driver message: (%s)", driver, msg WARN; /* was PRINT_IT */
    break;
  case RS_DBI_WARNING:
    PROBLEM "%s driver warning: (%s)", driver, msg WARN;
    break;
  case RS_DBI_ERROR:
    PROBLEM  "%s driver: (%s)", driver, msg ERROR;
    break;
  case RS_DBI_TERMINATE:
    PROBLEM "%s driver fatal: (%s)", driver, msg ERROR; /* was TERMINATE */
    break;
  }
  return;
}

void DBI_MSG(char *msg, DBI_EXCEPTION exception_type, char *driver)
{
  switch (exception_type) {
  case RS_DBI_MESSAGE:
    PROBLEM "%s driver message: (%s)", driver, msg WARN;
    break;
  case RS_DBI_WARNING:
    PROBLEM "%s driver warning: (%s)", driver, msg WARN;
    break;
  case RS_DBI_ERROR:
    PROBLEM  "%s driver: (%s)", driver, msg ERROR;
    break;
  case RS_DBI_TERMINATE:        /* is this used? */
    PROBLEM "%s driver fatal: (%s)", driver, msg ERROR;
    break;
  }
  return;
}

/* wrapper to strcpy */
char *
RS_DBI_copyString(const char *str)
{
  char *buffer;

  buffer = (char *) malloc((size_t) strlen(str)+1);
  if(!buffer)
    RS_DBI_errorMessage(
          "internal error in RS_DBI_copyString: could not alloc string space", 
          RS_DBI_ERROR);
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
      RS_DBI_errorMessage("unsupported data type", RS_DBI_ERROR);
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
  char *s;
  
  if(type==R_NilValue)
     RS_DBI_errorMessage(
           "internal error in RS_DBI_SclassNames: input S types must be nonNULL",
           RS_DBI_ERROR);
  n = LENGTH(type);
  typeCodes = INTEGER_DATA(type);
  PROTECT(typeNames = NEW_CHARACTER(n));
  for(i = 0; i < n; i++) {
    s = RS_DBI_getTypeName(typeCodes[i], RS_dataTypeTable);
    if(!s)
      RS_DBI_errorMessage(
            "internal error RS_DBI_SclassNames: unrecognized S type", 
            RS_DBI_ERROR);
    SET_CHR_EL(typeNames, i, mkChar(s));
  }
  UNPROTECT(1);
  return typeNames;
}

/* The following functions roughly implement a simple object
 * database. 
 */

SEXP
RS_DBI_asMgrHandle(int mgrId)
{
    SEXP mgrHandle, label, ids;
    PROTECT(ids = allocVector(INTSXP, 1));
    INTEGER(ids)[0] = mgrId;
    PROTECT(label = mkString("DBI MGR"));
    mgrHandle = R_MakeExternalPtr(NULL, label, ids);
    UNPROTECT(2);
    /* FIXME: add finalizer code */
    return mgrHandle;
}

/* FIXME: need to address this fwd declaration */
SEXP
RS_SQLite_closeConnection(Con_Handle conHandle);

static void _finalize_con_handle(SEXP xp)
{
    if (R_ExternalPtrAddr(xp)) {
        RS_SQLite_closeConnection(xp);
        R_ClearExternalPtr(xp);
    }
}

SEXP
RS_DBI_asConHandle(int mgrId, int conId, RS_DBI_connection *con)
{
    SEXP conHandle, s_ids, label;
    int *ids;
    PROTECT(s_ids = allocVector(INTSXP, 2));
    ids = INTEGER(s_ids);
    ids[0] = mgrId;
    ids[1] = conId;
    PROTECT(label = mkString("DBI CON"));
    conHandle = R_MakeExternalPtr(con, label, s_ids);
    UNPROTECT(2);
    R_RegisterCFinalizerEx(conHandle, _finalize_con_handle, 1);
    return conHandle;
}

SEXP
DBI_newResultHandle(SEXP xp, SEXP resId)
{
    int *ids = INTEGER(R_ExternalPtrProtected(xp));
    return RS_DBI_asResHandle(ids[0], ids[1], INTEGER(resId)[0], xp);
}

SEXP
RS_DBI_asResHandle(int mgrId, int conId, int resId, SEXP conxp)
{
    SEXP resHandle, s_ids, label, v;
    int *ids;
    PROTECT(s_ids = allocVector(INTSXP, 3));
    ids = INTEGER(s_ids);
    ids[0] = mgrId;
    ids[1] = conId;
    ids[2] = resId;
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

RS_DBI_manager* RS_DBI_getManager() {
  if (!dbManager) {
    RS_DBI_errorMessage(
      "internal error in RS_DBI_getManager: corrupt dbManager handle",
  	  RS_DBI_ERROR
    );
  }
  return dbManager;
}

RS_DBI_connection *
RS_DBI_getConnection(SEXP conHandle)
{
    RS_DBI_connection *con = (RS_DBI_connection *)R_ExternalPtrAddr(conHandle);
    if (!con) RS_DBI_errorMessage("expired SQLiteConnection", RS_DBI_ERROR);
    return con;
}

RS_DBI_resultSet *
RS_DBI_getResultSet(SEXP rsHandle)
{
  RS_DBI_connection *con;
  con = RS_DBI_getConnection(rsHandle);
  if(!con)
    RS_DBI_errorMessage(
          "internal error in RS_DBI_getResultSet: bad connection",
          RS_DBI_ERROR);
  return con->resultSets[0];
}

/* Very simple objectId (mapping) table. newEntry() returns an index
 * to an empty cell in table, and lookup() returns the position in the
 * table of obj_id.  Notice that we decided not to touch the entries
 * themselves to give total control to the invoking functions (this 
 * simplify error management in the invoking routines.)
 */
int
RS_DBI_newEntry(int *table, int length)
{
  int i, indx, empty_val;

  indx = empty_val = -1;
  for(i = 0; i < length; i++)
    if(table[i] == empty_val){
      indx = i;
      break;
    }
  return indx;
}

int
RS_DBI_lookup(int *table, int length, int obj_id)
{
  int i, indx = -1;
  if (obj_id != -1) {
      for (i = 0; i < length; ++i) {
          if (table[i] == obj_id) {
              indx = i;
              break;
          }
      }
  }
  return indx;
}

/* return a list of entries pointed by *entries (we allocate the space,
 * but the caller should free() it).  The function returns the number
 * of entries.
 */
int 
RS_DBI_listEntries(int *table, int length, int *entries)
{
  int i,n;

  for(i=n=0; i<length; i++){
    if(table[i]<0) continue;
    entries[n++] = table[i];
  }
  return n;
}

void 
RS_DBI_freeEntry(int *table, int indx)
{ /* no error checking!!! */
  int empty_val = -1;
  table[indx] = empty_val;
  return;
}

int 
is_validHandle(SEXP handle, HANDLE_TYPE handleType)
{
    int mgr_id, len, indx;
    RS_DBI_manager *mgr;
    RS_DBI_connection *con;

  if (TYPEOF(handle) != EXTPTRSXP) return 0;
  len = HANDLE_LENGTH(handle);
  if(len<handleType || handleType<1 || handleType>3) 
    return 0;
  mgr_id = MGR_ID(handle);
  if(mgr_id <= 0) return 0;

  /* at least we have a potential valid dbManager */
  mgr = dbManager;
  if(!mgr || !mgr->connections)  return 0;   /* expired manager*/
  if(handleType == MGR_HANDLE_TYPE) return 1;     /* valid manager id */

  /* ... on to connections */
  con = R_ExternalPtrAddr(handle);
  if (!con) return 0;
  if(!con->resultSets) return 0;       /* un-initialized (invalid) */
  if(handleType==CON_HANDLE_TYPE) return 1; /* valid connection id */

  /* .. on to resultSets */
  indx = RS_DBI_lookup(con->resultSetIds, con->length, RES_ID(handle));
  if(indx < 0) return 0;
  if(!con->resultSets[indx]) return 0;

  return 1;
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

/* given a type id return its human-readable name.
 * We define an RS_DBI_dataTypeTable */
char *
RS_DBI_getTypeName(int t, const struct data_types table[])
{
  int i;
  char buf[128];

  for (i = 0; table[i].typeName != (char *) 0; i++) {
    if (table[i].typeId == t)
      return table[i].typeName;
  }
  sprintf(buf, "unknown (%ld)", (long) t);
  RS_DBI_errorMessage(buf, RS_DBI_WARNING);
  return (char *) 0; /* for -Wall */
}

/* the codes come from from R/src/main/util.c */
const struct data_types RS_dataTypeTable[] = {
    { "NULL",		NILSXP	   },  /* real types */
    { "symbol",		SYMSXP	   },
    { "pairlist",	LISTSXP	   },
    { "closure",	CLOSXP	   },
    { "environment",	ENVSXP	   },
    { "promise",	PROMSXP	   },
    { "language",	LANGSXP	   },
    { "special",	SPECIALSXP },
    { "builtin",	BUILTINSXP },
    { "char",		CHARSXP	   },
    { "logical",	LGLSXP	   },
    { "integer",	INTSXP	   },
    { "double",		REALSXP	   }, /*-  "real", for R <= 0.61.x */
    { "complex",	CPLXSXP	   },
    { "character",	STRSXP	   },
    { "...",		DOTSXP	   },
    { "any",		ANYSXP	   },
    { "expression",	EXPRSXP	   },
    { "list",		VECSXP	   },
    { "raw",		RAWSXP	   },
    /* aliases : */
    { "numeric",	REALSXP	   },
    { "name",		SYMSXP	   },
    { (char *)0,	-1	   }
};
