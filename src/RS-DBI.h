#ifndef _RS_DBI_H
#define _RS_DBI_H 1
/*  
 *  $Id$
 *
 * Copyright (C) 1999-2002 The Omega Project for Statistical Computing.
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

/* The following include file defines a number of C macros that hide
 * differences between R and S (e.g., the macro for type "Sint" expand
 * to "long" in the case of S and to int in the case of R, etc.)
 */

#ifdef __cplusplus
extern "C" {
#endif

#include "Rhelpers.h"
#include <ctype.h>

/* Microsoft Visual C++ uses int _getpid()  */
#ifdef MSVC
#include <process.h>
#define getpid _getpid
#define pid_t int
#else
#include <sys/types.h>
#include <unistd.h>
#endif

pid_t getpid(); 

/* We now define 4 important data structures:
 * RS_DBI_manager, RS_DBI_connection, RS_DBI_resultSet, and
 * RS_DBI_fields, corresponding to dbManager, dbConnection,
 * dbResultSet, and list of field descriptions.
 */
/* In R/S a dbObject is a foreign reference consisting of a vector
 * of 1, 2 or 3 integers.  In the C implementation we use these 
 * R/S vectors as handles (we could have use pointers).
 */
typedef enum enum_dbi_exception {
  RS_DBI_MESSAGE,
  RS_DBI_WARNING,
  RS_DBI_ERROR,
  RS_DBI_TERMINATE
} DBI_EXCEPTION;

/* dbObject handles are simple S/R integer vectors of 1, 2, or 3 integers
 * the *_ID macros extract the appropriate scalar.
 */

#define Mgr_Handle SEXP
#define Con_Handle SEXP
#define Res_Handle SEXP
#define Db_Handle  SEXP       /* refers to any one of the above */
/* The integer value for the following enum's needs to equal 
 * GET_LENGTH(handle) for the various handles.
 */
typedef enum enum_handle_type {
  MGR_HANDLE_TYPE = 1,     /* dbManager handle */
  CON_HANDLE_TYPE = 2,     /* dbConnection handle */
  RES_HANDLE_TYPE = 3      /* dbResult handle */
} HANDLE_TYPE; 

#define MGR_ID(handle) INT_EL((handle),0)  /* the actual scalar mgr id */
#define CON_ID(handle) INT_EL((handle),1)  
#define RES_ID(handle) INT_EL((handle),2)

/* First, the following fully describes the field output by a select
 * (or select-like) statement, and the mappings from the internal
 * database types to S classes.  This structure contains the info we need
 * to build the R/S list (or data.frame) that will receive the SQL
 * output.  It still needs some work to handle arbitrty BLOB's (namely
 * methods to map BLOBs into user-defined S objects).
 * Each element is an array of num_fields, this flds->Sclass[3] stores
 * the S class for the 4th output fields.
 */
typedef struct st_sdbi_fields {
  int num_fields;
  char  **name;         /* DBMS field names */
  Sint  *type;          /* DBMS internal types */
  Sint  *length;        /* DBMS lengths in bytes */
  Sint  *precision;     /* DBMS num of digits for numeric types */
  Sint  *scale;         /* DBMS num of decimals for numeric types */
  Sint  *nullOk;        /* DBMS indicator for DBMS'  NULL type */
  Sint  *isVarLength;   /* DBMS variable-length char type */
  Stype *Sclass;        /* R/S class (type) -- may be overriden */
  /* TODO: Need a table of fun pointers to converters */
} RS_DBI_fields;

typedef struct st_sdbi_exception {
  DBI_EXCEPTION  exceptionType; /* one of RS_DBI_WARN, RS_RBI_ERROR, etc */
  int  errorNum;            /* SQL error number (possibly driver-dependent*/
  char *errorMsg;           /* SQL error message */
} RS_DBI_exception;

/* The RS-DBI resultSet consists of a pointer to the actual DBMS 
 * resultSet (e.g., MySQL, Oracle) possibly NULL,  plus the fields 
 * defined by the RS-DBI implementation. 
 */
typedef struct st_sdbi_resultset {
  void  *drvResultSet;   /* the actual (driver's) cursor/result set */
  void  *drvData;        /* a pointer to driver-specific data */
  Sint  managerId;       /* the 3 *Id's are used for   */
  Sint  connectionId;    /* validating stuff coming from S */
  Sint  resultSetId;  
  Sint  isSelect;        /* boolean for testing SELECTs */
  char  *statement;      /* SQL statement */
  Sint  rowsAffected;    /* used by non-SELECT statements */
  Sint  rowCount;        /* rows fetched so far (SELECT-types)*/
  Sint  completed;       /* have we fetched all rows? */
  RS_DBI_fields *fields;
} RS_DBI_resultSet;

/* A dbConnection consists of a pointer to the actual implementation
 * (MySQL, Oracle, etc.) connection plus a resultSet and other
 * goodies used by the RS-DBI implementation.
 * The connection parameters (user, password, database name, etc.) are
 * defined by the actual driver -- we just set aside a void pointer.
 */

typedef struct st_sdbi_connection {
  void  *conParams;      /* pointer to connection params (host, user, etc)*/
  void  *drvConnection;  /* pointer to the actual DBMS connection struct*/
  void  *drvData;        /* to be used at will by individual drivers */
  RS_DBI_resultSet  **resultSets;    /* vector to result set ptrs  */
  Sint   *resultSetIds;
  Sint   length;                     /* max num of concurrent resultSets */
  Sint   num_res;                    /* num of open resultSets */
  Sint   counter;                    /* total number of queries */
  Sint   managerId;
  Sint   connectionId; 
  RS_DBI_exception *exception;
} RS_DBI_connection;

/* dbManager */
typedef struct st_sdbi_manager {
  char *drvName;                    /* what driver are we implementing?*/
  void *drvData;                    /* to be used by the drv implementation*/
  RS_DBI_connection **connections;  /* list of dbConnections */
  Sint *connectionIds;              /* array of connectionIds */
  Sint length;                      /* max num of concurrent connections */
  Sint num_con;                     /* num of opened connections */
  Sint counter;                     /* num of connections handled so far*/
  Sint fetch_default_rec;           /* default num of records per fetch */
  Sint managerId;                   /* typically, process id */
  RS_DBI_exception *exception;    
} RS_DBI_manager;

/* All RS_DBI functions and their signatures */

/* Note: the following alloc functions allocate the space for the
 * corresponding manager, connection, resultSet; they all 
 * return handles.  All DBI functions (free/get/etc) use the handle 
 * to work with the various dbObjects.
 */
Mgr_Handle RS_DBI_allocManager(const char *drvName, Sint max_con, 
				    Sint fetch_default_rec, 
				    Sint force_realloc);
void            RS_DBI_freeManager(Mgr_Handle mgrHandle);
RS_DBI_manager *RS_DBI_getManager(Db_Handle handle);
Mgr_Handle RS_DBI_asMgrHandle(Sint pid);   
SEXP RS_DBI_managerInfo(Mgr_Handle mgrHandle);

/* dbConnection */
Con_Handle RS_DBI_allocConnection(Mgr_Handle mgrHandle, 
					  Sint max_res);
void               RS_DBI_freeConnection(Con_Handle conHandle);
RS_DBI_connection *RS_DBI_getConnection(Db_Handle handle);
Con_Handle RS_DBI_asConHandle(Sint mgrId, Sint conId);
SEXP RS_DBI_connectionInfo(Con_Handle con_Handle);

/* dbResultSet */
Res_Handle RS_DBI_allocResultSet(Con_Handle conHandle);
void               RS_DBI_freeResultSet(Res_Handle rsHandle);
RS_DBI_resultSet  *RS_DBI_getResultSet(Res_Handle rsHandle);
Res_Handle RS_DBI_asResHandle(Sint pid, Sint conId, Sint resId);
SEXP RS_DBI_resultSetInfo(Res_Handle rsHandle);

/* utility funs */
SEXP RS_DBI_validHandle(Db_Handle handle); /* callable from S/R */
int       is_validHandle(Db_Handle handle, HANDLE_TYPE handleType);

/* a simple object database (mapping table) -- it uses simple linear 
 * search (we don't expect to have more than a handful of simultaneous 
 * connections and/or resultSets. If this is not the case, we could
 * use a hash table, but I doubt it's worth it (famous last words!).
 * These are used for storing/retrieving object ids, such as
 * connection ids from the manager object, and resultSet ids from a 
 * connection object;  of course, this is transparent to the various
 * drivers -- they should deal with handles exclusively.
 */
Sint  RS_DBI_newEntry(Sint *table, Sint length);
Sint  RS_DBI_lookup(Sint *table, Sint length, Sint obj_id);
Sint  RS_DBI_listEntries(Sint *table, Sint length, Sint *entries);
void  RS_DBI_freeEntry(Sint *table, Sint indx);

/* description of the fields in a result set */
RS_DBI_fields *RS_DBI_allocFields(int num_fields);
SEXP RS_DBI_getFieldDescriptions(RS_DBI_fields *flds);
void           RS_DBI_freeFields(RS_DBI_fields *flds);

/* we (re)allocate the actual output list in here (with the help of
 * RS_DBI_fields).  This should be some kind of R/S "relation"
 * table, not a dataframe nor a list.
 */
void  RS_DBI_allocOutput(SEXP output, 
			RS_DBI_fields *flds,
			Sint num_rec,
			Sint expand);
void RS_DBI_makeDataFrame(SEXP data);

/* TODO: We need to elevate RS_DBI_errorMessage to either
 * dbManager and/or dbConnection methods.  I still need to 
 * go back and re-code the error-handling throughout, darn!
 */
void  RS_DBI_errorMessage(char *msg, DBI_EXCEPTION exceptionType);
void  RS_DBI_setException(Db_Handle handle, 
			  DBI_EXCEPTION exceptionType,
			  int errorNum, 
			  const char *errorMsg);
void DBI_MSG(char *msg, DBI_EXCEPTION exception_type, char *driver);

/* utility funs (copy strings, convert from R/S types to string, etc.*/
char     *RS_DBI_copyString(const char *str);
char     *RS_DBI_nCopyString(const char *str, size_t len, int del_blanks);

/* We now define a generic data type name-Id mapping struct
 * and initialize the RS_dataTypeTable[].  Each driver could
 * define similar table for generating friendly type names
 */
struct data_types {
    char *typeName;
    Sint typeId;
};

/* return the primitive type name for a primitive type id */
char     *RS_DBI_getTypeName(Sint typeCode, const struct data_types table[]);
/* same, but callable from S/R and vectorized */
SEXP RS_DBI_SclassNames(SEXP types);  

SEXP RS_DBI_createNamedList(char  **names, 
				 Stype *types,
				 Sint  *lengths,
				 Sint  n);
SEXP RS_DBI_copyFields(RS_DBI_fields *flds);

void RS_na_set(void *ptr, Stype type);
int  RS_is_na(void *ptr, Stype type);
extern const struct data_types RS_dataTypeTable[];

#ifdef __cplusplus 
}
#endif
#endif   /* _RS_DBI_H */
