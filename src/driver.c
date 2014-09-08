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

SQLiteDriver* rsqlite_driver() {
  if (!dbManager) error("Corrupt dbManager handle.");
  return dbManager;
}

void rsqlite_driver_init(SEXP records_, SEXP cache_) {
  if (dbManager) return; // Already allocated

  const char *clientVersion = sqlite3_libversion();
  if (strcmp(clientVersion, compiledVersion)) {
    error("SQLite mismatch between compiled version %s and runtime version %s",
      compiledVersion, clientVersion
    );
  }
  
  dbManager = malloc(sizeof(SQLiteDriver));
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

SEXP rsqlite_driver_close() {
  SQLiteDriver *mgr = rsqlite_driver();
  if (mgr->num_con) {
    error("Open connections -- close them first");    
  }
  sqlite3_enable_shared_cache(0);

  return ScalarLogical(1);
}


SEXP rsqlite_driver_valid() {
  if (!rsqlite_driver()) return ScalarLogical(0);
      
  return ScalarLogical(1);
}


SEXP rsqlite_driver_info() {
  SQLiteDriver* mgr = rsqlite_driver();
  
  SEXP info = PROTECT(allocVector(VECSXP, 5));
  SEXP info_nms = PROTECT(allocVector(STRSXP, 5));
  SET_NAMES(info, info_nms);
  UNPROTECT(1);

  int i = 0;
  SET_STRING_ELT(info_nms, i, mkChar("fetch_default_rec"));
  SET_VECTOR_ELT(info, i++, ScalarInteger(mgr->fetch_default_rec));

  SET_STRING_ELT(info_nms, i, mkChar("num_con"));
  SET_VECTOR_ELT(info, i++, ScalarInteger(mgr->num_con));

  SET_STRING_ELT(info_nms, i, mkChar("counter"));
  SET_VECTOR_ELT(info, i++, ScalarInteger(mgr->counter));

  SET_STRING_ELT(info_nms, i, mkChar("clientVersion"));
  SET_VECTOR_ELT(info, i++, mkString(SQLITE_VERSION));

  SET_STRING_ELT(info_nms, i, mkChar("shared_cache"));
  SET_VECTOR_ELT(info, i++, ScalarLogical(mgr->shared_cache));
  
  UNPROTECT(1);
  return info;
}
