/*
 * Copyright (C) 1999-2003 The Omega Project for Statistical Computing.
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

char *compiledVersion = SQLITE_VERSION;

// Driver ----------------------------------------------------------------------

static SQLiteDriver *dbManager = NULL;

SQLiteDriver* getDriver() {
  if (!dbManager) error("Corrupt dbManager handle.");
  return dbManager;
}

void initDriver(SEXP records_, SEXP cache_) {
  if (dbManager) return; // Already allocated

  const char *clientVersion = sqlite3_libversion();
  if (strcmp(clientVersion, compiledVersion)) {
    error("SQLite mismatch between compiled version %s and runtime version %s",
      compiledVersion, clientVersion
    );
  }
  
  dbManager = (SQLiteDriver*) malloc(sizeof(SQLiteDriver));
  if (!dbManager) {
    error("could not malloc the dbManger");
  }
    
  dbManager->counter = 0;
  dbManager->num_con = 0;
  dbManager->fetch_default_rec = asInteger(records_);
  
  if (asLogical(cache_)) {
    dbManager->shared_cache = 1;
    sqlite3_enable_shared_cache(1);
  } else {
    dbManager->shared_cache = 0;
  }
  
  return;
}

SEXP closeDriver() {
  SQLiteDriver *mgr = getDriver();
  if (mgr->num_con) {
    error("Open connections -- close them first");    
  }
  sqlite3_enable_shared_cache(0);

  return ScalarLogical(1);
}


SEXP isValidDriver() {
  if (!getDriver()) return ScalarLogical(0);
      
  return ScalarLogical(1);
}


SEXP driverInfo() {
  SQLiteDriver* mgr = getDriver();
   
  char *mgrDesc[] = {"fetch_default_rec", "num_con", 
                     "counter",   "clientVersion", "shared_cache"};
  SEXPTYPE mgrType[] = {INTSXP, INTSXP, INTSXP,
                        STRSXP, STRSXP };
  int  mgrLen[]  = {1, 1, 1, 1, 1};

  int j = 0;  
  SEXP output = PROTECT(RS_DBI_createNamedList(mgrDesc, mgrType, mgrLen, 5));
  SET_VECTOR_ELT(output, j++, ScalarInteger(mgr->fetch_default_rec));
  SET_VECTOR_ELT(output, j++, ScalarInteger(mgr->num_con));
  SET_VECTOR_ELT(output, j++, ScalarInteger(mgr->counter));
  SET_VECTOR_ELT(output, j++, mkString(SQLITE_VERSION));
  SET_VECTOR_ELT(output, j++, ScalarLogical(mgr->shared_cache));
  UNPROTECT(1);
  
  return output;
}
