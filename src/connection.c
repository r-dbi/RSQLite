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

static void _finalize_connection_handle(SEXP xp) {
  if (!R_ExternalPtrAddr(xp)) return;

  close_connection(xp);
}

SQLiteConnection* rsqlite_connection_from_handle(SEXP handle) {
  SQLiteConnection* con = (SQLiteConnection*) R_ExternalPtrAddr(handle);
  if (!con)
    error("expired SQLiteConnection");

  return con;
}

SEXP new_connection(SEXP dbname_, SEXP allow_ext_, SEXP flags_,
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
  SQLiteConnection* con = malloc(sizeof(SQLiteConnection));
  if (con == NULL) {
    error("could not malloc dbConnection");
  }
  con->exception = NULL;
  con->resultSet = NULL;

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
  SQLiteDriver* driver = rsqlite_driver();
  driver->num_con += 1;
  driver->counter += 1;

  rsqlite_exception_set(con, SQLITE_OK, "OK");

  // Create handle
  SEXP handle = R_MakeExternalPtr(con, R_NilValue, R_NilValue);
  R_RegisterCFinalizerEx(handle, _finalize_connection_handle, 1);
  return handle;
}


SEXP close_connection(SEXP handle) {
  SQLiteConnection* con = rsqlite_connection_from_handle(handle);

  // close & free result set (if open)
  if (con->resultSet) {
    warning("Closing open result set");
    rsqlite_result_free(con);
  }

  // close & free db connection
  sqlite3* db_connection = con->drvConnection;
  int rc = sqlite3_close(db_connection);  /* it also frees db_connection */
  if (rc == SQLITE_BUSY) {
    warning("Unfinalized prepared statements.");
  } else if (rc != SQLITE_OK) {
    warning("Internal error: could not close SQLte connection.");
  }
  con->drvConnection = NULL;
  rsqlite_exception_free(con);

  // update driver connection table
  SQLiteDriver* drv = rsqlite_driver();
  drv->num_con -= 1;

  free(con);
  con = NULL;
  R_ClearExternalPtr(handle);

  return ScalarLogical(1);
}

SEXP isValidConnection(SEXP dbObj) {
  SQLiteConnection* con = R_ExternalPtrAddr(dbObj);

  if (!con)
    return ScalarLogical(0);
  if (!con->drvConnection)
    return ScalarLogical(0);

  return ScalarLogical(1);
}

SEXP connectionInfo(SEXP conHandle) {
  SQLiteConnection* con = rsqlite_connection_from_handle(conHandle);

  SEXP info = PROTECT(allocVector(VECSXP, 2));
  SEXP info_nms = PROTECT(allocVector(STRSXP, 2));
  SET_NAMES(info, info_nms);
  UNPROTECT(1);

  int i = 0;
  SET_STRING_ELT(info_nms, i, mkChar("serverVersion"));
  SET_VECTOR_ELT(info, i++, mkString(SQLITE_VERSION));

  SET_STRING_ELT(info_nms, i, mkChar("results"));
  SET_VECTOR_ELT(info, i++, ScalarLogical(con->resultSet != NULL));

  UNPROTECT(1);
  return info;
}
