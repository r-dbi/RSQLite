#ifndef _RSQLITE_H
#define _RSQLITE_H 1
/*  
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

#ifdef __cplusplus
extern "C" {
#endif

#include <ctype.h>
#include <string.h>
#include "sqlite.h"
#include "Rversion.h"
#include "Rdefines.h"
#include "S.h"
#include <R_ext/RS.h>

// DBI -------------------------------------------------------------------------

/* We now define 4 important data structures:
 * SQLiteDriver, RS_DBI_connection, RS_DBI_resultSet, and
 * RS_DBI_fields, corresponding to dbManager, dbConnection,
 * dbResultSet, and list of field descriptions.
 */

typedef enum enum_dbi_exception {
  RS_DBI_MESSAGE,
  RS_DBI_WARNING,
  RS_DBI_ERROR,
  RS_DBI_TERMINATE
} DBI_EXCEPTION;


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
  int  *type;          /* DBMS internal types */
  int  *length;        /* DBMS lengths in bytes */
  int  *isVarLength;   /* DBMS variable-length char type */
  SEXPTYPE *Sclass;        /* R/S class (type) -- may be overriden */
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
  int  resultSetId;  
  int  isSelect;        /* boolean for testing SELECTs */
  char  *statement;      /* SQL statement */
  int  rowsAffected;    /* used by non-SELECT statements */
  int  rowCount;        /* rows fetched so far (SELECT-types)*/
  int  completed;       /* have we fetched all rows? */
  RS_DBI_fields *fields;
} RS_DBI_resultSet;

/* A dbConnection consists of a pointer to the actual implementation
 * (MySQL, Oracle, etc.) connection plus a resultSet and other
 * goodies used by the RS-DBI implementation.
 * The connection parameters (user, password, database name, etc.) are
 * defined by the actual driver -- we just set aside a void pointer.
 */

typedef struct st_sdbi_connection {
  void  *drvConnection;  /* pointer to the actual DBMS connection struct*/
  RS_DBI_resultSet  *resultSet;    /* vector to result set ptrs  */
  RS_DBI_exception *exception;
} RS_DBI_connection;

/* dbManager */
typedef struct st_sdbi_manager {
  int shared_cache;                /* use SQLite shared cache? */
  int num_con;                     /* num of opened connections */
  int counter;                     /* num of connections handled so far*/
  int fetch_default_rec;           /* default num of records per fetch */
  RS_DBI_exception *exception;    
} SQLiteDriver;

/* All RS_DBI functions and their signatures */

SQLiteDriver* getDriver();

/* dbConnection */
void RS_DBI_freeConnection(SEXP conHandle);
RS_DBI_connection *RS_DBI_getConnection(SEXP handle);
SEXP RS_DBI_asConHandle(RS_DBI_connection *con);

/* dbResultSet */
SEXP RS_DBI_allocResultSet(SEXP conHandle);
void RS_DBI_freeResultSet0(RS_DBI_resultSet *result, RS_DBI_connection *con);
RS_DBI_resultSet  *RS_DBI_getResultSet(SEXP rsHandle);
SEXP RS_DBI_asResHandle(SEXP conxp);
void RSQLite_freeResultSet0(RS_DBI_resultSet *result, RS_DBI_connection *con);

void setException(RS_DBI_connection *con, int err_no, 
                            const char *err_msg);
void freeException(RS_DBI_connection *con);

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
			int num_rec,
			int expand);

/* utility funs (copy strings, convert from R/S types to string, etc.*/
char     *RS_DBI_copyString(const char *str);

/* same, but callable from S/R and vectorized */
SEXP RS_DBI_SclassNames(SEXP types);  

SEXP RS_DBI_createNamedList(char  **names, 
				 SEXPTYPE *types,
				 int  *lengths,
				 int  n);
SEXP RS_DBI_copyFields(RS_DBI_fields *flds);

SEXP DBI_newResultHandle(SEXP xp, SEXP resId);

// SQLite ----------------------------------------------------------------------


/* These control the open mode for new connections and
   are mapped to the appropriate SQLite flag.
 */
#define RSQLITE_RWC 0
#define RSQLITE_RW  1
#define RSQLITE_RO  2

/* SQLite connection parameters struct, allocating and freeing
 * methods.  This is pretty simple, since SQLite does not recognise users
 */
typedef struct st_sdbi_conParams {
  char *dbname;
  int  loadable_extensions;
  int  flags;
  char *vfs;
} RS_SQLite_conParams;

typedef struct st_sqlite_err {
   int  errorNum;
   char *errorMsg;
} RS_SQLite_exception;

/* Convert declared column type string to SQLite column type.
 * For example, "varchar" => SQLITE_TEXT
 *
 */
int                 SQLite_decltype_to_type(const char *decltype);

/* The following functions are the S/R entry into the C implementation (i.e.,
 * these are the only ones visible from R/S) we use the prefix "RS_SQLite" in
 * function names to denote this.  These functions are  built on top of the
 * underlying RS_DBI manager, connection, and resultsets structures and
 * functions (see RS-DBI.h).
 *
 */

/* dbManager */
void initDriver(SEXP records_, SEXP cache_);
SEXP RS_SQLite_close(SEXP mgrHandle);

/* dbConnection */
SEXP RS_SQLite_newConnection(SEXP dbfile,
                                   SEXP allow_ext, SEXP s_flags, SEXP s_vfs);
SEXP RS_SQLite_cloneConnection(SEXP conHandle);
SEXP RS_SQLite_closeConnection(SEXP conHandle);
/* we simulate db exceptions ourselves */
void        RS_SQLite_setException(RS_DBI_connection *con, int errorNum,
                                   const char *errorMsg);
SEXP RS_SQLite_getException(SEXP conHandle);
/* err No, Msg */

/* currently we only provide a "standard" callback to sqlite_exec() -- this
 * callback collects all the rows and puts them in a cache in the results set
 * (res->drvData) to simulate a cursor so that we can fetch() like in any other
 * driver.  Other interesting callbacks should allow us to easily implement the
 * dbApply() ideas also in the RMySQL driver
 */
int       RS_SQLite_stdCallback(void *resHandle, int ncol, char **row,
                                char **colNames);

/* dbResultSet */
SEXP RS_SQLite_exec(SEXP conHandle, SEXP statement,
                           SEXP bind_data);
SEXP RS_SQLite_fetch(SEXP rsHandle, SEXP max_rec);
SEXP RS_SQLite_closeResultSet(SEXP rsHandle);
void        RS_SQLite_initFields(RS_DBI_resultSet *res, int ncol,
                                 char **colNames);

SEXP RS_SQLite_validHandle(SEXP handle);      /* boolean */

RS_DBI_fields *RS_SQLite_createDataMappings(SEXP resHandle);

/* the following funs return named lists with meta-data for
 * the manager, connections, and  result sets, respectively.
 */
SEXP RS_SQLite_managerInfo(SEXP mgrHandle);
SEXP RSQLite_connectionInfo(SEXP conHandle);
SEXP RS_SQLite_resultSetInfo(SEXP rsHandle);

/*  The following imports the delim-fields of a file into an existing table*/
SEXP RS_SQLite_importFile(SEXP conHandle, SEXP s_tablename,
             SEXP s_filename, SEXP s_separator, SEXP s_obj,
             SEXP s_skip);

SEXP RS_SQLite_copy_database(SEXP fromConHandle, SEXP toConHandle);

char * RS_sqlite_getline(FILE *in, const char *eol);

/* the following type names should be the  SQL-92 data types, and should
 * be moved to the RS-DBI.h
 */
enum SQLITE_TYPE {
  SQLITE_TYPE_NULL,
  SQLITE_TYPE_INTEGER,
  SQLITE_TYPE_REAL,
  SQLITE_TYPE_TEXT,
  SQLITE_TYPE_BLOB
};

int RS_sqlite_import(sqlite3 *db, const char *zTable,
                     const char *zFile, const char *separator, const char *eol, int skip);

void RSQLite_closeResultSet0(RS_DBI_resultSet *result, RS_DBI_connection *con);

// R helpers -------------------------------------------------------------------

/* x[i] */
#define LGL_EL(x,i) LOGICAL_POINTER((x))[(i)]
#define INT_EL(x,i) INTEGER_POINTER((x))[(i)]
#define NUM_EL(x,i) NUMERIC_POINTER((x))[(i)]
#define LST_EL(x,i) VECTOR_ELT((x),(i))
#define CHR_EL(x,i) CHAR(STRING_ELT((x),(i)))
#define SET_CHR_EL(x,i,val)  SET_STRING_ELT((x),(i), (val))

/* x[[i]][j] -- can be also assigned if x[[i]] is a numeric type */
#define LST_CHR_EL(x,i,j) CHR_EL(LST_EL((x),(i)), (j))
#define LST_LGL_EL(x,i,j) LGL_EL(LST_EL((x),(i)), (j))
#define LST_INT_EL(x,i,j) INT_EL(LST_EL((x),(i)), (j))
#define LST_NUM_EL(x,i,j) NUM_EL(LST_EL((x),(i)), (j))
#define LST_LST_EL(x,i,j) LST_EL(LST_EL((x),(i)), (j))

/* x[[i]][j] -- for the case when x[[i]] is a character type */
#define SET_LST_CHR_EL(x,i,j,val) SET_STRING_ELT(LST_EL(x,i), j, val)

// Param binding ---------------------------------------------------------------

typedef struct st_sqlite_bindparams {
    int count;
    int row_count;
    int rows_used;
    int row_complete;
    SEXP data;
} RS_SQLite_bindParams;


RS_SQLite_bindParams *
RS_SQLite_createParameterBinding(int n,
                                 SEXP bind_data, sqlite3_stmt *stmt,
                                 char *errorMsg);

void RS_SQLite_freeParameterBinding(RS_SQLite_bindParams **);


#ifdef __cplusplus 
}
#endif
#endif   /* _RSQLITE_H */
