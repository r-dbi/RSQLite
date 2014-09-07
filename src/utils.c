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



int SQLite_decltype_to_type(const char* decltype)
{
    unsigned int h = 0;
    if (!decltype)
        return SQLITE_TEXT;
    int len = strlen(decltype);
    const unsigned char *zIn = (unsigned char*)decltype;
    const unsigned char *zEnd = (unsigned char*)&(decltype[len]);
    int col_type = SQLITE_FLOAT;

    while( zIn!=zEnd ){
        h = (h<<8) + tolower(*zIn);
        zIn++;
        if( h==(('c'<<24)+('h'<<16)+('a'<<8)+'r') ){             /* CHAR */
            col_type = SQLITE_TEXT;
        }else if( h==(('c'<<24)+('l'<<16)+('o'<<8)+'b') ){       /* CLOB */
            col_type = SQLITE_TEXT;
        }else if( h==(('t'<<24)+('e'<<16)+('x'<<8)+'t') ){       /* TEXT */
            col_type = SQLITE_TEXT;
        }else if( h==(('b'<<24)+('l'<<16)+('o'<<8)+'b')          /* BLOB */
                  && col_type==SQLITE_FLOAT ){
            col_type = SQLITE_BLOB;
#ifndef SQLITE_OMIT_FLOATING_POINT
        }else if( h==(('r'<<24)+('e'<<16)+('a'<<8)+'l')          /* REAL */
                  && col_type==SQLITE_FLOAT ){
            col_type = SQLITE_FLOAT;
        }else if( h==(('f'<<24)+('l'<<16)+('o'<<8)+'a')          /* FLOA */
                  && col_type==SQLITE_FLOAT ){
            col_type = SQLITE_FLOAT;
        }else if( h==(('d'<<24)+('o'<<16)+('u'<<8)+'b')          /* DOUB */
                  && col_type==SQLITE_FLOAT ){
            col_type = SQLITE_FLOAT;
#endif
        }else if( (h&0x00FFFFFF)==(('i'<<16)+('n'<<8)+'t') ){    /* INT */
            col_type = SQLITE_INTEGER;
            break;
        }
    }
    return col_type;
}



char* field_type(int type) {
  switch(type) {
    case SQLITE_TYPE_NULL:    return "NULL";
    case SQLITE_TYPE_INTEGER: return "INTEGER";
    case SQLITE_TYPE_REAL:    return "REAL";
    case SQLITE_TYPE_TEXT:    return "TEXT";
    case SQLITE_TYPE_BLOB:    return "BLOB";
    default:                  return "unknown";
  }
}

SEXP typeNames(SEXP typeIds) {
  int n = LENGTH(typeIds);
  int* typeCodes = INTEGER(typeIds);
  SEXP typeNames = PROTECT(allocVector(STRSXP, n));
  for(int i = 0; i < n; i++) {
    char* s = field_type(typeCodes[i]);
    SET_STRING_ELT(typeNames, i, mkChar(s));
  }
  UNPROTECT(1);
  return typeNames;
}


SEXP RS_SQLite_copy_database(SEXP fromConHandle, SEXP toConHandle)
{
    sqlite3_backup *backup = NULL;
    RS_DBI_connection *fromCon = RS_DBI_getConnection(fromConHandle);
    RS_DBI_connection *toCon = RS_DBI_getConnection(toConHandle);
    sqlite3 *dbFrom = (sqlite3 *)fromCon->drvConnection;
    sqlite3 *dbTo = (sqlite3 *)toCon->drvConnection;
    int rc = 0;

    backup = sqlite3_backup_init(dbTo, "main", dbFrom, "main");
    if (backup) {
        sqlite3_backup_step(backup, -1);
        sqlite3_backup_finish(backup);
    }
    rc = sqlite3_errcode(dbTo);
    if (rc != SQLITE_OK) {
        setException(toCon, rc, sqlite3_errmsg(dbTo));
        error(sqlite3_errmsg(dbTo));
    }
    return R_NilValue;
}
