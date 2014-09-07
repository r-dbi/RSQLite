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

#include <R.h>
#include <Rdefines.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include "sqlite.h"

// DBI -------------------------------------------------------------------------

typedef struct RS_SQLite_bindParams {
    int count;
    int row_count;
    int rows_used;
    int row_complete;
    SEXP data;
} RS_SQLite_bindParams;

/* First, the following fully describes the field output by a select
 * (or select-like) statement, and the mappings from the internal
 * database types to S classes.  This structure contains the info we need
 * to build the R/S list (or data.frame) that will receive the SQL
 * output.
 */
typedef struct RS_DBI_fields {
  int num_fields;
  char  **name;         /* DBMS field names */
  int  *type;          /* DBMS internal types */
  int  *length;        /* DBMS lengths in bytes */
  int  *isVarLength;   /* DBMS variable-length char type */
  SEXPTYPE *Sclass;        /* R/S class (type) -- may be overriden */
} RS_DBI_fields;

typedef struct RS_SQLite_exception {
   int  errorNum;
   char *errorMsg;
} RS_SQLite_exception;

/* The RS-DBI resultSet consists of a pointer to the actual DBMS 
 * resultSet (e.g., MySQL, Oracle) possibly NULL,  plus the fields 
 * defined by the RS-DBI implementation. 
 */
typedef struct RS_DBI_resultSet {
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

enum SQLITE_TYPE {
  SQLITE_TYPE_NULL,
  SQLITE_TYPE_INTEGER,
  SQLITE_TYPE_REAL,
  SQLITE_TYPE_TEXT,
  SQLITE_TYPE_BLOB
};

typedef struct SQLiteConnection {
  sqlite3* drvConnection;  
  RS_DBI_resultSet  *resultSet;
  RS_SQLite_exception *exception;
} SQLiteConnection;

typedef struct SQLiteDriver {
  int shared_cache;                /* use SQLite shared cache? */
  int num_con;                     /* num of opened connections */
  int counter;                     /* num of connections handled so far*/
  int fetch_default_rec;           /* default num of records per fetch */
} SQLiteDriver;

// Functions ===================================================================

// Result ----------------------------------------------------------------------

SEXP RS_DBI_allocResultSet(SEXP conHandle);
void RS_DBI_freeResultSet0(RS_DBI_resultSet *result, SQLiteConnection *con);
RS_DBI_resultSet  *RS_DBI_getResultSet(SEXP rsHandle);
SEXP RS_DBI_asResHandle(SEXP conxp);
void RSQLite_freeResultSet0(RS_DBI_resultSet *result, SQLiteConnection *con);
RS_DBI_fields *RS_DBI_allocFields(int num_fields);
SEXP fieldInfo(RS_DBI_fields *flds);
void RS_DBI_freeFields(RS_DBI_fields *flds);
void RS_DBI_allocOutput(SEXP output, RS_DBI_fields *flds, int num_rec, int expand);
SEXP DBI_newResultHandle(SEXP xp, SEXP resId);
SEXP RS_SQLite_exec(SEXP conHandle, SEXP statement, SEXP bind_data);
SEXP RS_SQLite_fetch(SEXP rsHandle, SEXP max_rec);
SEXP RS_SQLite_closeResultSet(SEXP rsHandle);
void  RS_SQLite_initFields(RS_DBI_resultSet *res, int ncol, char **colNames);
RS_DBI_fields *RS_SQLite_createDataMappings(SEXP resHandle);
RS_SQLite_bindParams* RS_SQLite_createParameterBinding(int n, SEXP bind_data, sqlite3_stmt *stmt, char *errorMsg);
void RS_SQLite_freeParameterBinding(RS_SQLite_bindParams **);
void RSQLite_closeResultSet0(RS_DBI_resultSet *result, SQLiteConnection *con);

// Exception -------------------------------------------------------------------

void setException(SQLiteConnection *con, int err_no, const char *err_msg);
void freeException(SQLiteConnection *con);
void RS_SQLite_setException(SQLiteConnection *con, int errorNum, const char *errorMsg);
SEXP RS_SQLite_getException(SEXP conHandle);

// Connection ------------------------------------------------------------------

SQLiteConnection *get_connection(SEXP handle);
SEXP connection_handle(SQLiteConnection *con);
SEXP new_connection(SEXP dbfile, SEXP allow_ext, SEXP s_flags, SEXP s_vfs);
SEXP close_connection(SEXP conHandle);

// Driver ----------------------------------------------------------------------

SQLiteDriver* getDriver();
void initDriver(SEXP records_, SEXP cache_);
SEXP RS_SQLite_close(SEXP mgrHandle);

// Utilities -------------------------------------------------------------------

char* RS_DBI_copyString(const char *str);
SEXP RS_DBI_copyFields(RS_DBI_fields *flds);
int SQLite_decltype_to_type(const char *decltype);
SEXP RS_SQLite_importFile(SEXP conHandle, SEXP s_tablename, SEXP s_filename, SEXP s_separator, SEXP s_obj, SEXP s_skip);
char * RS_sqlite_getline(FILE *in, const char *eol);
SEXP RS_SQLite_copy_database(SEXP fromConHandle, SEXP toConHandle);
int RS_sqlite_import(sqlite3 *db, const char *zTable, const char *zFile, const char *separator, const char *eol, int skip);
char* field_type(int type);

#ifdef __cplusplus 
}
#endif
#endif   /* _RSQLITE_H */
