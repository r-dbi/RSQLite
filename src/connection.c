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

RS_DBI_connection *
RS_DBI_getConnection(SEXP conHandle)
{
    RS_DBI_connection *con = (RS_DBI_connection *)R_ExternalPtrAddr(conHandle);
    if (!con) error("expired SQLiteConnection");
    return con;
}


SEXP RS_SQLite_newConnection(SEXP dbname_, SEXP allow_ext_, SEXP flags_, 
                             SEXP vfs_) {
  const char* dbname = CHAR(asChar(dbname_));
  
  if (!isLogical(allow_ext_)) {
    error("'allow_ext' must be TRUE or FALSE");
  }
  int allow_ext = asLogical(allow_ext_);
  if (allow_ext == NA_LOGICAL)
    error("'allow_ext' must be TRUE or FALSE, not NA");
  
  if (!isInteger(flags_)) {
    error("'flags' must be integer");
  }
  int flags = asInteger(flags_);
  
  const char* vfs = NULL;
  if (!isNull(vfs_)) {
    vfs = CHAR(asChar(vfs_));
    if (strlen(vfs) == 0) vfs = NULL;
  }
  
  // Create external pointer to connection object
  RS_DBI_connection* con = (RS_DBI_connection *) malloc(sizeof(RS_DBI_connection));
  if (!con){
    error("could not malloc dbConnection");
  }
  con->exception = (RS_SQLite_exception *) NULL;  
  con->resultSet = (RS_DBI_resultSet *) NULL;

  // Initialise SQLite3 database connection
  sqlite3* db_connection;
  int rc = sqlite3_open_v2(dbname, &db_connection, flags, vfs);
  if (rc != SQLITE_OK) {
    error("Could not connect to database:\n%s", sqlite3_errmsg(db_connection));
  }
  if (allow_ext) {
    sqlite3_enable_load_extension(db_connection, 1);
  }
  con->drvConnection = db_connection;
  
  // Finally, update connection table in driver
  SQLiteDriver* driver = getDriver();
  driver->num_con += 1;
  driver->counter += 1;
  
  setException(con, SQLITE_OK, "OK");
    
  return RS_DBI_asConHandle(con);
}

SEXP RS_SQLite_closeConnection(SEXP conHandle) {
  RS_DBI_connection *con = RS_DBI_getConnection(conHandle);
  
  if (con->resultSet) {
    warning("Closing open result set");
    RSQLite_closeResultSet0(con->resultSet, con);
  }

  sqlite3* db_connection = con->drvConnection;
  int rc = sqlite3_close(db_connection);  /* it also frees db_connection */
  if (rc == SQLITE_BUSY) {
    warning("Unfinalized prepared statements.");
  } else if(rc!=SQLITE_OK){
    warning("Internal error: could not close SQLte connection.");
  }
  con->drvConnection = NULL;
  freeException(con);
  RS_DBI_freeConnection(conHandle);
  
  return ScalarLogical(1);
}

SEXP isValidConnection(SEXP dbObj) {
  RS_DBI_connection* con = R_ExternalPtrAddr(dbObj);

  if (!con) return ScalarLogical(0);
  if (!con->drvConnection) return ScalarLogical(0);
  
  return ScalarLogical(1);
}


SEXP connectionInfo(SEXP conHandle) {

  SEXP info = PROTECT(allocVector(VECSXP, 1));
  SEXP info_nms = PROTECT(allocVector(STRSXP, 1));
  SET_NAMES(info, info_nms);
  UNPROTECT(1);

  int i = 0;
  SET_STRING_ELT(info_nms, i, mkChar("serverVersion"));
  SET_VECTOR_ELT(info, i++, mkString(SQLITE_VERSION));

  UNPROTECT(1);
  return info;
}
