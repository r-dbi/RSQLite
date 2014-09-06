/* Convenience macros for R programming */

#ifndef RHELPERS_H
#define RHELPERS_H

#ifdef __cplusplus
extern "C" {
#endif

#include "Rversion.h"
#include "Rdefines.h"
#include "S.h"

/* x[i] */
#define LGL_EL(x,i) LOGICAL_POINTER((x))[(i)]
#define INT_EL(x,i) INTEGER_POINTER((x))[(i)]
#define NUM_EL(x,i) NUMERIC_POINTER((x))[(i)]
#define LST_EL(x,i) VECTOR_ELT((x),(i))
#define CHR_EL(x,i) CHAR(STRING_ELT((x),(i)))
#define SET_CHR_EL(x,i,val)  SET_STRING_ELT((x),(i), (val))

/* x[[i]][j] -- can be also assigned if x[[i]] is a numeric type */
#define LST_CHR_EL(x,i,j) CHR_EL(LST_EL((x),(i)), (j))
#define LST_LGL_EL(x,i,j) LGL_EL(LST_EL((x),(i)), (j))
#define LST_INT_EL(x,i,j) INT_EL(LST_EL((x),(i)), (j))
#define LST_NUM_EL(x,i,j) NUM_EL(LST_EL((x),(i)), (j))
#define LST_LST_EL(x,i,j) LST_EL(LST_EL((x),(i)), (j))

/* x[[i]][j] -- for the case when x[[i]] is a character type */
#define SET_LST_CHR_EL(x,i,j,val) SET_STRING_ELT(LST_EL(x,i), j, val)

/* end of RS-DBI macros */

#ifdef __cplusplus
}
#endif

#endif /* RHELPERS_H */
