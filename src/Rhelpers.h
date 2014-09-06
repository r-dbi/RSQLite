/* Convenience macros for R programming */

#ifndef RHELPERS_H
#define RHELPERS_H

#ifdef __cplusplus
extern "C" {
#endif

#include "Rversion.h"
#include "Rdefines.h"
#include "S.h"
#define Sint  int
#define C_S_CPY(p)    COPY_TO_USER_STRING(p)    /* cpy C string to R */


/* x[i] */
#define LGL_EL(x,i) LOGICAL_POINTER((x))[(i)]
#define INT_EL(x,i) INTEGER_POINTER((x))[(i)]
#define SGL_EL(x,i) SINGLE_POINTER((x))[(i)]
#define FLT_EL(x,i) SGL_EL((x),(i))
#define NUM_EL(x,i) NUMERIC_POINTER((x))[(i)]
#define DBL_EL(x,i) NUM_EL((x),(i))
#define RAW_EL(x,i) RAW_POINTER((x))[(i)]
#define LST_EL(x,i) VECTOR_ELT((x),(i))
#define CHR_EL(x,i) CHAR(STRING_ELT((x),(i)))
#define SET_CHR_EL(x,i,val)  SET_STRING_ELT((x),(i), (val))

/* x[[i]][j] -- can be also assigned if x[[i]] is a numeric type */
#define LST_CHR_EL(x,i,j) CHR_EL(LST_EL((x),(i)), (j))
#define LST_LGL_EL(x,i,j) LGL_EL(LST_EL((x),(i)), (j))
#define LST_INT_EL(x,i,j) INT_EL(LST_EL((x),(i)), (j))
#define LST_SGL_EL(x,i,j) SGL_EL(LST_EL((x),(i)), (j))
#define LST_FLT_EL(x,i,j) LST_SGL_EL((x),(i),(j))
#define LST_NUM_EL(x,i,j) NUM_EL(LST_EL((x),(i)), (j))
#define LST_DBL_EL(x,i,j) LST_NUM_EL((x),(i),(j))
#define LST_RAW_EL(x,i,j) RAW_EL(LST_EL((x),(i)), (j))
#define LST_LST_EL(x,i,j) LST_EL(LST_EL((x),(i)), (j))

/* x[[i]][j] -- for the case when x[[i]] is a character type */
#define SET_LST_CHR_EL(x,i,j,val) SET_STRING_ELT(LST_EL(x,i), j, val)

/* end of RS-DBI macros */

#ifdef __cplusplus
}
#endif

#endif /* RHELPERS_H */
