/* S4 (Splus5+) and R portability macros.
 *
 * This file provides additional macros to the ones in Rdefines.h (in R)
 * and S4/Splus5 S.h (see Appendix A of the green book) to 
 * allow portability between R > 1.0.0, S4, and Splus5+ at the C source
 * level.  In addition to the macros in Rdefines.h and Appendix A,
 * we have macros to do x[[i][j] and x[[i]][j] <- val inside C functions,
 * macros to test for primitive data types, plus macros to test and 
 * set NA's portably.
 * TODO: Macros to build and eval functions portably?
 */

#ifndef S4R_H
#define S4R_H

#include "S.h" 

#ifdef __cplusplus
extern "C" {
#endif

/* Some of these come from MASS, some from packages developed under
 * the Omega project, and some from RS-DBI itself.
 */

#if (defined(SPLUS_VERSION) && SPLUS_VERSION >= 5000 )
#  define USING_SP5
#elif (defined(S_VERSION)) /* && S_VERSION = "4-M" )  */
#  define USING_S4
#endif

#ifdef USING_R
#  include "Rversion.h"
#  if defined(R_VERSION) && R_VERSION >= R_Version(1,2,0)
#    define USE_RINTERNALS 1           /* buggy Rdefines.h in 1.2.0/1.2.1 */
#    include "Rdefines.h"
#    ifdef SET_ELEMENT                 /* workaround for bug in Rdefines.h */
#      undef SET_ELEMENT
#      define SET_ELEMENT(x,i,val) SET_VECTOR_ELT((x),(i),(val))
#    endif   /* SET_ELEMENT */
#  else
#    include "Rdefines.h"
#  endif
#  define singl double
#  define Sint  int
#  define charPtr SEXP *
#  define CHAR_DEREF(x) CHAR(x)
#  define C_S_CPY(p)    COPY_TO_USER_STRING(p)    /* cpy C string to R */
#  define MEM_PROTECT(x) PROTECT(x)
#  define MEM_UNPROTECT(n) UNPROTECT(n)
#  define MEM_UNPROTECT_PTR(x) UNPROTECT_PTR(x)
#elif (defined(USING_S4) || defined(USING_SP5))
#  define singl float
#  define Sint long
#  define charPtr char **
#  define CHAR_DEREF(x) x
#  define C_S_CPY(p)    c_s_cpy((p), S_evaluator) /* cpy C string to S */
#  define RAW_DATA(p)   (RAW_POINTER(p))           /* missing in S4 S.h */
#  define MEM_PROTECT(x)  (x) /**/
#  define MEM_UNPROTECT(n) /**/
#  define MEM_UNPROTECT_PTR(x) /**/
#endif

/* The following are macros defined in the Green Book, but missing
 * in Rdefines.h.  The semantics are as close to S4's as possible (?).
 */
#ifdef USING_R
#  define COPY(x) duplicate(x)                  
#  define COPY_ALL(x) duplicate(x)               
#  define EVAL_IN_FRAME(expr,n)  eval(expr,n)     
#  define GET_FROM_FRAME(name,n) findVar(install(name),n)
#  define ASSIGN_IN_FRAME(name,obj,n) defineVar(install(name),COPY(obj),n)
#endif

/* data types common to R and S4 */
#ifdef USING_R
#  define Stype          SEXPTYPE
#  define LOGICAL_TYPE	 LGLSXP
#  define INTEGER_TYPE	 INTSXP
#  define NUMERIC_TYPE	 REALSXP
#  define SINGLE_TYPE    REALSXP
#  define REAL_TYPE      REALSXP
#  define CHARACTER_TYPE STRSXP
#  define STRING_TYPE    STRSXP
#  define COMPLEX_TYPE	 CPLXSXP
#  define LIST_TYPE	 VECSXP
#else
#  define Stype           int
#  define LOGICAL_TYPE	  LGL
#  define INTEGER_TYPE	  INT
#  define NUMERIC_TYPE	  DOUBLE
#  define SINGLE_TYPE     REAL
#  define REAL_TYPE       REAL
#  define CHARACTER_TYPE  CHAR
#  define STRING_TYPE     CHAR
#  define COMPLEX_TYPE	  COMPLEX
#  define LIST_TYPE	  LIST
#  define RAW_TYPE	  RAW
#endif

#ifdef USING_R
#  undef INTEGER_DATA
#  define INTEGER_DATA(x) (INTEGER(x))
#  undef S_NULL_ENTRY
#  define S_NULL_ENTRY R_NilValue
#else
#  define S_NULL_ENTRY  NULL_ENTRY
#endif

/* We simplify one- and two-level access to object and list
 * (mostly built on top of jmc's macros)
 *
 * NOTE: Recall that list element vectors should *not* be set 
 * directly, but only thru SET_ELEMENT (Green book, Appendix A), e.g.,
 *      LIST_POINTER(x)[i] = NEW_CHARACTER(100);    BAD!!
 *      LST_EL(x,i) = NEW_CHARACTER(100);           BAD!!
 *      SET_ELEMENT(x, i, NEW_CHARACTER(100));      Okay
 *
 * It's okay to directly set the i'th element of the j'th list element:
 *      LST_CHR_EL(x,i,j) = C_S_CPY(str);           Okay (but not in R-1.2.1)
 *
 * For R >= 1.2.0 define
 *      SET_LST_CHR_EL(x,i,j,val)
 */

/* x[i] */
#define LGL_EL(x,i) LOGICAL_POINTER((x))[(i)]
#define INT_EL(x,i) INTEGER_POINTER((x))[(i)]
#define SGL_EL(x,i) SINGLE_POINTER((x))[(i)]
#define FLT_EL(x,i) SGL_EL((x),(i))
#define NUM_EL(x,i) NUMERIC_POINTER((x))[(i)]
#define DBL_EL(x,i) NUM_EL((x),(i))
#define RAW_EL(x,i) RAW_POINTER((x))[(i)]
#if defined(R_VERSION) && R_VERSION >= R_Version(1,2,0) 
#  define LST_EL(x,i) VECTOR_ELT((x),(i))
#  define CHR_EL(x,i) CHAR_DEREF(STRING_ELT((x),(i)))
#  define SET_CHR_EL(x,i,val)  SET_STRING_ELT((x),(i), (val))
#else     /* the following are valid for S4/Splus5 and R < 1.2.0 */
#  define LST_EL(x,i) LIST_POINTER((x))[(i)]  
#  define CHR_EL(x,i) CHAR_DEREF(CHARACTER_POINTER((x))[(i)])
#  define SET_CHR_EL(x,i,val)  (CHR_EL(x,i)=val)
#endif

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
#if defined(R_VERSION) && R_VERSION >= R_Version(1,2,0) 
#  define SET_LST_CHR_EL(x,i,j,val) SET_STRING_ELT(LST_EL(x,i), j, val)
#else   
#  define SET_LST_CHR_EL(x,i,j,val) (CHR_EL(LST_EL(x,i),j)=val)
#endif

/* setting and querying NA's -- in the case of R, we need to
 * use our own RS_na_set and RS_is_na functions (these need work!)
 */

#ifdef USING_R
#  define NA_SET(p,t)   RS_na_set((p),(t))
#  define NA_CHR_SET(p) SET_CHR_EL(p, 0, NA_STRING)
#  define IS_NA(p,t)    RS_is_na((p),(t))
#else
#  define NA_SET(p,t)   na_set((p),(t))
#  define NA_CHR_SET(p) (p) = C_S_CPY(NA_STRING)
#  define IS_NA(p,t)    is_na((p), (t))
#endif


/* SET_ROWNAMES() and SET_CLASS_NAME() don't exist in S4 
 */
#ifdef USING_R
#  define SET_ROWNAMES(df,n)  setAttrib(df, R_RowNamesSymbol, n)
#  define GET_CLASS_NAME(x)   GET_CLASS(x)
#  define SET_CLASS_NAME(x,n) SET_CLASS(x, n)
#else
#  define SET_ROWNAMES(df,n)  error("un-implemented macro SET_ROWNAMES")
#  define SET_CLASS_NAME(x,n) error("un-implemented macro SET_CLASS_NAME")
#endif

/* end of RS-DBI macros */

#ifdef __cplusplus
}
#endif

#endif /* S4R_H */
