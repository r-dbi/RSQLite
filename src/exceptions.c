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

void setException(RS_DBI_connection *con, int err_no, 
                            const char *err_msg) {

  RS_SQLite_exception* ex = (RS_SQLite_exception *) con->exception;
  if (!ex) {
    // Create new exception object
    ex = (RS_SQLite_exception *) malloc(sizeof(RS_SQLite_exception));
    if (!ex) {
      error("could not allocate SQLite exception object");
    }
  } else {
    // Reuse existing
    free(ex->errorMsg);
  }

  ex->errorNum = err_no;
  if (err_msg) {
    ex->errorMsg = RS_DBI_copyString(err_msg);
  } else { 
    ex->errorMsg = (char *) NULL;
  }
  
  con->exception = ex;
  return;
}

void freeException(RS_DBI_connection *con) {
  RS_SQLite_exception *ex = (RS_SQLite_exception *) con->exception;

  if (!ex) 
    return;
  if (ex->errorMsg) 
    free(ex->errorMsg);
  free(ex);
  
  con->exception = NULL;
  return;
}

/* return a 2-elem list with the last exception number and exception message on a given connection.
 * NOTE: RS_SQLite_getException() is meant to be used mostly directory R.
 */
SEXP 
RS_SQLite_getException(SEXP conHandle)
{
    SEXP output;
    RS_DBI_connection   *con = RS_DBI_getConnection(conHandle);
    RS_SQLite_exception *err;
    int n = 2;
    char *exDesc[] = {"errorNum", "errorMsg"};
    SEXPTYPE exType[] = {INTSXP, STRSXP};
    int  exLen[]  = {1, 1};

    if(!con->drvConnection)
        error("internal error: corrupt connection handle");
    PROTECT(output = RS_DBI_createNamedList(exDesc, exType, exLen, n));
    err = (RS_SQLite_exception *) con->exception;
    LST_INT_EL(output,0,0) = err->errorNum;
    SET_LST_CHR_EL(output,1,0,mkChar(err->errorMsg));
    UNPROTECT(1);
    return output;
}
