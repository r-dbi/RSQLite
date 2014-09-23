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
char*
RS_DBI_copyString(const char* str) {
  char* buffer;

  buffer = malloc((size_t) strlen(str) + 1);
  if (!buffer)
    error("internal error in RS_DBI_copyString: could not alloc string space");
  return strcpy(buffer, str);
}

int SQLite_decltype_to_type(const char* decltype) {
  unsigned int h = 0;
  if (!decltype)
    return SQLITE_TEXT;
  int len = strlen(decltype);
  const unsigned char* zIn = (unsigned char*) decltype;
  const unsigned char* zEnd = (unsigned char*) &(decltype[len]);
  int col_type = SQLITE_FLOAT;

  while (zIn != zEnd) {
    h = (h << 8) + tolower(*zIn);
    zIn++;
    if (h == (('c' << 24) + ('h' << 16) + ('a' << 8) + 'r')) {             /* CHAR */
      col_type = SQLITE_TEXT;
    } else if (h == (('c' << 24) + ('l' << 16) + ('o' << 8) + 'b')) {       /* CLOB */
      col_type = SQLITE_TEXT;
    } else if (h == (('t' << 24) + ('e' << 16) + ('x' << 8) + 't')) {       /* TEXT */
      col_type = SQLITE_TEXT;
    } else if (h == (('b' << 24) + ('l' << 16) + ('o' << 8) + 'b')          /* BLOB */
        && col_type == SQLITE_FLOAT) {
      col_type = SQLITE_BLOB;
#ifndef SQLITE_OMIT_FLOATING_POINT
    } else if (h == (('r' << 24) + ('e' << 16) + ('a' << 8) + 'l')          /* REAL */
        && col_type == SQLITE_FLOAT) {
      col_type = SQLITE_FLOAT;
    } else if (h == (('f' << 24) + ('l' << 16) + ('o' << 8) + 'a')          /* FLOA */
        && col_type == SQLITE_FLOAT) {
      col_type = SQLITE_FLOAT;
    } else if (h == (('d' << 24) + ('o' << 16) + ('u' << 8) + 'b')          /* DOUB */
        && col_type == SQLITE_FLOAT) {
      col_type = SQLITE_FLOAT;
#endif
    } else if ((h & 0x00FFFFFF) == (('i' << 16) + ('n' << 8) + 't')) {    /* INT */
      col_type = SQLITE_INTEGER;
      break;
    }
  }
  return col_type;
}


char* field_type(int type) {
  switch (type) {
    case SQLITE_TYPE_NULL:
      return "NULL";
    case SQLITE_TYPE_INTEGER:
      return "INTEGER";
    case SQLITE_TYPE_REAL:
      return "REAL";
    case SQLITE_TYPE_TEXT:
      return "TEXT";
    case SQLITE_TYPE_BLOB:
      return "BLOB";
    default:
      return "unknown";
  }
}


SEXP RS_SQLite_copy_database(SEXP fromConHandle, SEXP toConHandle) {
  sqlite3_backup* backup = NULL;
  SQLiteConnection* fromCon = rsqlite_connection_from_handle(fromConHandle);
  SQLiteConnection* toCon = rsqlite_connection_from_handle(toConHandle);
  sqlite3* dbFrom = (sqlite3*) fromCon->drvConnection;
  sqlite3* dbTo = (sqlite3*) toCon->drvConnection;
  int rc = 0;

  backup = sqlite3_backup_init(dbTo, "main", dbFrom, "main");
  if (backup) {
    sqlite3_backup_step(backup, -1);
    sqlite3_backup_finish(backup);
  }
  rc = sqlite3_errcode(dbTo);
  if (rc != SQLITE_OK) {
    rsqlite_exception_set(toCon, rc, sqlite3_errmsg(dbTo));
    error(sqlite3_errmsg(dbTo));
  }
  return R_NilValue;
}
