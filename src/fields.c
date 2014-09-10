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

SQLiteFields* rsqlite_fields_alloc(int n) {
  SQLiteFields* flds;

  flds = malloc(sizeof(SQLiteFields));
  if (!flds) {
    error("Could not malloc SQLiteFields.");
  }
  flds->num_fields = n;
  flds->name = calloc(n, sizeof(char*));
  flds->type = calloc(n, sizeof(int));
  flds->length = calloc(n, sizeof(int));
  flds->Sclass = calloc(n, sizeof(SEXPTYPE));

  return flds;
}

void rsqlite_fields_free(SQLiteFields* flds) {
  if (flds->name) free(flds->name);
  if (flds->type) free(flds->type);
  if (flds->length) free(flds->length);
  if (flds->Sclass) free(flds->Sclass);
  free(flds);
  flds = NULL;
  return;
}

SEXP rsqlite_field_info(SQLiteFields* flds) {
  int n = flds ? flds->num_fields : 0;

  SEXP info = PROTECT(allocVector(VECSXP, 4));
  SEXP info_nms = PROTECT(allocVector(STRSXP, 4));
  SET_NAMES(info, info_nms);
  UNPROTECT(1);

  int i = 0;
  SET_STRING_ELT(info_nms, i, mkChar("name"));
  SEXP names = PROTECT(allocVector(STRSXP, n));
  for (int j = 0; j < n; j++) {
    SET_STRING_ELT(names, j, mkChar(flds->name[j]));
  }
  SET_VECTOR_ELT(info, i++, names);
  UNPROTECT(1);

  SET_STRING_ELT(info_nms, i, mkChar("Sclass"));
  SEXP sclass = PROTECT(allocVector(STRSXP, n));
  for (int j = 0; j < n; j++) {
    const char* type = type2char(flds->Sclass[j]);
    SET_STRING_ELT(sclass, j, mkChar(type));
  }
  SET_VECTOR_ELT(info, i++, sclass);
  UNPROTECT(1);

  SET_STRING_ELT(info_nms, i, mkChar("type"));
  SEXP types = PROTECT(allocVector(STRSXP, n));
  for (int j = 0; j < n; j++) {
    char* type = field_type(flds->type[j]);
    SET_STRING_ELT(types, j, mkChar(type));
  }
  SET_VECTOR_ELT(info, i++, types);
  UNPROTECT(1);

  SET_STRING_ELT(info_nms, i, mkChar("len"));
  SEXP lens = PROTECT(allocVector(INTSXP, n));
  for (int j = 0; j < n; j++) {
    INTEGER(lens)[j] = flds->length[j];
  }
  SET_VECTOR_ELT(info, i++, lens);
  UNPROTECT(1);

  UNPROTECT(1);
  return info;
}
