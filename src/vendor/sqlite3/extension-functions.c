/*
This library will provide common mathematical and string functions in
SQL queries using the operating system libraries or provided
definitions.  It includes the following functions:

Math: acos, asin, atan, atn2, atan2, acosh, asinh, atanh, difference,
degrees, radians, cos, sin, tan, cot, cosh, sinh, tanh, coth, exp,
log, log10, power, sign, sqrt, square, ceil, floor, pi.

String: replicate, charindex, leftstr, rightstr, ltrim, rtrim, trim,
replace, reverse, proper, padl, padr, padc, strfilter.

Aggregate: stdev, variance, mode, median, lower_quartile,
upper_quartile.

The string functions ltrim, rtrim, trim, replace are included in
recent versions of SQLite and so by default do not build.

Compilation instructions:
 Compile this C source file into a dynamic library as follows:
 * Linux:
   gcc -fPIC -lm -shared extension-functions.c -o libsqlitefunctions.so
 * Mac OS X:
   gcc -fno-common -dynamiclib extension-functions.c -o libsqlitefunctions.dylib
 (You may need to add flags
  -I /opt/local/include/ -L/opt/local/lib -lsqlite3
  if your sqlite3 is installed from Mac ports, or
  -I /sw/include/ -L/sw/lib -lsqlite3
  if installed with Fink.)
 * Windows:
  1. Install MinGW (http://www.mingw.org/) and you will get the gcc
  (gnu compiler collection)
  2. add the path to your path variable (isn't done during the
   installation!)
  3. compile:
   gcc -shared -I "path" -o libsqlitefunctions.so extension-functions.c
   (path = path of sqlite3ext.h; i.e. C:\programs\sqlite)

Usage instructions for applications calling the sqlite3 API functions:
  In your application, call sqlite3_enable_load_extension(db,1) to
  allow loading external libraries.  Then load the library libsqlitefunctions
  using sqlite3_load_extension; the third argument should be 0.
  See http://www.sqlite.org/cvstrac/wiki?p=LoadableExtensions.
  Select statements may now use these functions, as in
  SELECT cos(radians(inclination)) FROM satsum WHERE satnum = 25544;

Usage instructions for the sqlite3 program:
  If the program is built so that loading extensions is permitted,
  the following will work:
   sqlite> SELECT load_extension('./libsqlitefunctions.so');
   sqlite> select cos(radians(45));
   0.707106781186548
  Note: Loading extensions is by default prohibited as a
  security measure; see "Security Considerations" in
  http://www.sqlite.org/cvstrac/wiki?p=LoadableExtensions.
  If the sqlite3 program and library are built this
  way, you cannot use these functions from the program, you
  must write your own program using the sqlite3 API, and call
  sqlite3_enable_load_extension as described above, or else
  rebuilt the sqlite3 program to allow loadable extensions.

Alterations:
The instructions are for Linux, Mac OS X, and Windows; users of other
OSes may need to modify this procedure.  In particular, if your math
library lacks one or more of the needed trig or log functions, comment
out the appropriate HAVE_ #define at the top of file.  If you do not
wish to make a loadable module, comment out the define for
COMPILE_SQLITE_EXTENSIONS_AS_LOADABLE_MODULE.  If you are using a
version of SQLite without the trim functions and replace, comment out
the HAVE_TRIM #define.

Liam Healy

History:
2010-01-06 Correct check for argc in squareFunc, and add Windows
compilation instructions.
2009-06-24 Correct check for argc in properFunc.
2008-09-14 Add check that memory was actually allocated after
sqlite3_malloc or sqlite3StrDup, call sqlite3_result_error_nomem if
not.  Thanks to Robert Simpson.
2008-06-13 Change to instructions to indicate use of the math library
and that program might work.
2007-10-01 Minor clarification to instructions.
2007-09-29 Compilation as loadable module is optional with
COMPILE_SQLITE_EXTENSIONS_AS_LOADABLE_MODULE.
2007-09-28 Use sqlite3_extension_init and macros
SQLITE_EXTENSION_INIT1, SQLITE_EXTENSION_INIT2, so that it works with
sqlite3_load_extension.  Thanks to Eric Higashino and Joe Wilson.
New instructions for Mac compilation.
2007-09-17 With help from Joe Wilson and Nuno Luca, made use of
external interfaces so that compilation is no longer dependent on
SQLite source code.  Merged source, header, and README into a single
file.  Added casts so that Mac will compile without warnings (unsigned
and signed char).
2007-09-05 Included some definitions from sqlite 3.3.13 so that this
will continue to work in newer versions of sqlite.  Completed
description of functions available.
2007-03-27 Revised description.
2007-03-23 Small cleanup and a bug fix on the code.  This was mainly
letting errno flag errors encountered in the math library and checking
the result, rather than pre-checking.  This fixes a bug in power that
would cause an error if any non-positive number was raised to any
power.
2007-02-07 posted by Mikey C to sqlite mailing list.
Original code 2006 June 05 by relicoder.

*/

//#include "config.h"

#define COMPILE_SQLITE_EXTENSIONS_AS_LOADABLE_MODULE 1
#define HAVE_ACOSH 1
#define HAVE_ASINH 1
#define HAVE_ATANH 1
#define HAVE_SINH 1
#define HAVE_COSH 1
#define HAVE_TANH 1
#define HAVE_LOG10 1
#define HAVE_ISBLANK 1
#define SQLITE_SOUNDEX 1
#define HAVE_TRIM 1		/* LMH 2007-03-25 if sqlite has trim functions */

#ifdef COMPILE_SQLITE_EXTENSIONS_AS_LOADABLE_MODULE
#include "sqlite3ext.h"
SQLITE_EXTENSION_INIT1
#else
#include "sqlite3.h"
#endif

#include <ctype.h>
/* relicoder */
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>		/* LMH 2007-03-25 */

#include <stdlib.h>
#include <assert.h>

#ifndef _MAP_H_
#define _MAP_H_

#include <stdint.h>

/*
** Simple binary tree implementation to use in median, mode and quartile calculations
** Tree is not necessarily balanced. That would require something like red&black trees of AVL
*/

typedef int(*cmp_func)(const void *, const void *);
typedef void(*map_iterator)(void*, int64_t, void*);

typedef struct node{
  struct node *l;
  struct node *r;
  void* data;
  int64_t count;
} node;

typedef struct map{
  node *base;
  cmp_func cmp;
} map;

/*
** creates a map given a comparison function
*/
map map_make(cmp_func cmp);

/*
** inserts the element e into map m
*/
void map_insert(map *m, void *e);

/*
** executes function iter over all elements in the map, in key increasing order
*/
void map_iterate(map *m, map_iterator iter, void* p);

/*
** frees all memory used by a map
*/
void map_destroy(map *m);

/*
** compares 2 integers
** to use with map_make
*/
int int_cmp(const void *a, const void *b);

/*
** compares 2 doubles
** to use with map_make
*/
int double_cmp(const void *a, const void *b);

#endif /* _MAP_H_ */

typedef uint8_t         u8;
typedef uint16_t        u16;
typedef int64_t         i64;

static char *sqlite3StrDup( const char *z ) {
    char *res = sqlite3_malloc( strlen(z)+1 );
    return strcpy( res, z );
}

/*
** These are copied verbatim from fun.c so as to not have the names exported
*/

/* LMH from sqlite3 3.3.13 */
/*
** This table maps from the first byte of a UTF-8 character to the number
** of trailing bytes expected. A value '4' indicates that the table key
** is not a legal first byte for a UTF-8 character.
*/
static const u8 xtra_utf8_bytes[256]  = {
/* 0xxxxxxx */
0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,

/* 10wwwwww */
4, 4, 4, 4, 4, 4, 4, 4,     4, 4, 4, 4, 4, 4, 4, 4,
4, 4, 4, 4, 4, 4, 4, 4,     4, 4, 4, 4, 4, 4, 4, 4,
4, 4, 4, 4, 4, 4, 4, 4,     4, 4, 4, 4, 4, 4, 4, 4,
4, 4, 4, 4, 4, 4, 4, 4,     4, 4, 4, 4, 4, 4, 4, 4,

/* 110yyyyy */
1, 1, 1, 1, 1, 1, 1, 1,     1, 1, 1, 1, 1, 1, 1, 1,
1, 1, 1, 1, 1, 1, 1, 1,     1, 1, 1, 1, 1, 1, 1, 1,

/* 1110zzzz */
2, 2, 2, 2, 2, 2, 2, 2,     2, 2, 2, 2, 2, 2, 2, 2,

/* 11110yyy */
3, 3, 3, 3, 3, 3, 3, 3,     4, 4, 4, 4, 4, 4, 4, 4,
};


/*
** This table maps from the number of trailing bytes in a UTF-8 character
** to an integer constant that is effectively calculated for each character
** read by a naive implementation of a UTF-8 character reader. The code
** in the READ_UTF8 macro explains things best.
*/
static const int xtra_utf8_bits[] =  {
  0,
  12416,          /* (0xC0 << 6) + (0x80) */
  925824,         /* (0xE0 << 12) + (0x80 << 6) + (0x80) */
  63447168        /* (0xF0 << 18) + (0x80 << 12) + (0x80 << 6) + 0x80 */
};

/*
** If a UTF-8 character contains N bytes extra bytes (N bytes follow
** the initial byte so that the total character length is N+1) then
** masking the character with utf8_mask[N] must produce a non-zero
** result.  Otherwise, we have an (illegal) overlong encoding.
*/
static const int utf_mask[] = {
  0x00000000,
  0xffffff80,
  0xfffff800,
  0xffff0000,
};

/* LMH salvaged from sqlite3 3.3.13 source code src/utf.c */
#define READ_UTF8(zIn, c) { \
  int xtra;                                            \
  c = *(zIn)++;                                        \
  xtra = xtra_utf8_bytes[c];                           \
  switch( xtra ){                                      \
    case 4: c = (int)0xFFFD; break;                    \
    case 3: c = (c<<6) + *(zIn)++;                     \
    case 2: c = (c<<6) + *(zIn)++;                     \
    case 1: c = (c<<6) + *(zIn)++;                     \
    c -= xtra_utf8_bits[xtra];                         \
    if( (utf_mask[xtra]&c)==0                          \
        || (c&0xFFFFF800)==0xD800                      \
        || (c&0xFFFFFFFE)==0xFFFE ){  c = 0xFFFD; }    \
  }                                                    \
}

static int sqlite3ReadUtf8(const unsigned char *z){
  int c;
  READ_UTF8(z, c);
  return c;
}

#define SKIP_UTF8(zIn) {                               \
  zIn += (xtra_utf8_bytes[*(u8 *)zIn] + 1);            \
}

/*
** pZ is a UTF-8 encoded unicode string. If nByte is less than zero,
** return the number of unicode characters in pZ up to (but not including)
** the first 0x00 byte. If nByte is not less than zero, return the
** number of unicode characters in the first nByte of pZ (or up to
** the first 0x00, whichever comes first).
*/
static int sqlite3Utf8CharLen(const char *z, int nByte){
  int r = 0;
  const char *zTerm;
  if( nByte>=0 ){
    zTerm = &z[nByte];
  }else{
    zTerm = (const char *)(-1);
  }
  assert( z<=zTerm );
  while( *z!=0 && z<zTerm ){
    SKIP_UTF8(z);
    r++;
  }
  return r;
}

/*
** X is a pointer to the first byte of a UTF-8 character.  Increment
** X so that it points to the next character.  This only works right
** if X points to a well-formed UTF-8 string.
*/
#define sqliteNextChar(X)  while( (0xc0&*++(X))==0x80 ){}
#define sqliteCharVal(X)   sqlite3ReadUtf8(X)

/*
** This is a macro that facilitates writting wrappers for math.h functions
** it creates code for a function to use in SQlite that gets one numeric input
** and returns a floating point value.
**
** Could have been implemented using pointers to functions but this way it's inline
** and thus more efficient. Lower * ranking though...
**
** Parameters:
** name:      function name to de defined (eg: sinFunc)
** function:  function defined in math.h to wrap (eg: sin)
** domain:    boolean condition that CAN'T happen in terms of the input parameter rVal
**            (eg: rval<0 for sqrt)
*/
/* LMH 2007-03-25 Changed to use errno and remove domain; no pre-checking for errors. */
#define GEN_MATH_WRAP_DOUBLE_1(name, function) \
static void name(sqlite3_context *context, int argc, sqlite3_value **argv){\
  double rVal = 0.0, val;\
  assert( argc==1 );\
  switch( sqlite3_value_type(argv[0]) ){\
    case SQLITE_NULL: {\
      sqlite3_result_null(context);\
      break;\
    }\
    default: {\
      rVal = sqlite3_value_double(argv[0]);\
      errno = 0;\
      val = function(rVal);\
      if (errno == 0) {\
        sqlite3_result_double(context, val);\
      } else {\
        sqlite3_result_error(context, strerror(errno), errno);\
      }\
      break;\
    }\
  }\
}\


/*
** Example of GEN_MATH_WRAP_DOUBLE_1 usage
** this creates function sqrtFunc to wrap the math.h standard function sqrt(x)=x^0.5
*/
GEN_MATH_WRAP_DOUBLE_1(sqrtFunc, sqrt)

/* trignometric functions */
GEN_MATH_WRAP_DOUBLE_1(acosFunc, acos)
GEN_MATH_WRAP_DOUBLE_1(asinFunc, asin)
GEN_MATH_WRAP_DOUBLE_1(atanFunc, atan)

/*
** Many of systems don't have inverse hyperbolic trig functions so this will emulate
** them on those systems in terms of log and sqrt (formulas are too trivial to demand
** written proof here)
*/

#ifndef HAVE_ACOSH
static double acosh(double x){
  return log(x + sqrt(x*x - 1.0));
}
#endif

GEN_MATH_WRAP_DOUBLE_1(acoshFunc, acosh)

#ifndef HAVE_ASINH
static double asinh(double x){
  return log(x + sqrt(x*x + 1.0));
}
#endif

GEN_MATH_WRAP_DOUBLE_1(asinhFunc, asinh)

#ifndef HAVE_ATANH
static double atanh(double x){
  return (1.0/2.0)*log((1+x)/(1-x)) ;
}
#endif

GEN_MATH_WRAP_DOUBLE_1(atanhFunc, atanh)

/*
** math.h doesn't require cot (cotangent) so it's defined here
*/
static double cot(double x){
  return 1.0/tan(x);
}

GEN_MATH_WRAP_DOUBLE_1(sinFunc, sin)
GEN_MATH_WRAP_DOUBLE_1(cosFunc, cos)
GEN_MATH_WRAP_DOUBLE_1(tanFunc, tan)
GEN_MATH_WRAP_DOUBLE_1(cotFunc, cot)

static double coth(double x){
  return 1.0/tanh(x);
}

/*
** Many systems don't have hyperbolic trigonometric functions so this will emulate
** them on those systems directly from the definition in terms of exp
*/
#ifndef HAVE_SINH
static double sinh(double x){
  return (exp(x)-exp(-x))/2.0;
}
#endif

GEN_MATH_WRAP_DOUBLE_1(sinhFunc, sinh)

#ifndef HAVE_COSH
static double cosh(double x){
  return (exp(x)+exp(-x))/2.0;
}
#endif

GEN_MATH_WRAP_DOUBLE_1(coshFunc, cosh)

#ifndef HAVE_TANH
static double tanh(double x){
  return sinh(x)/cosh(x);
}
#endif

GEN_MATH_WRAP_DOUBLE_1(tanhFunc, tanh)

GEN_MATH_WRAP_DOUBLE_1(cothFunc, coth)

/*
** Some systems lack log in base 10. This will emulate it
*/

#ifndef HAVE_LOG10
static double log10(double x){
  static double l10 = -1.0;
  if( l10<0.0 ){
    l10 = log(10.0);
  }
  return log(x)/l10;
}
#endif

GEN_MATH_WRAP_DOUBLE_1(logFunc, log)
GEN_MATH_WRAP_DOUBLE_1(log10Func, log10)
GEN_MATH_WRAP_DOUBLE_1(expFunc, exp)

/*
** Fallback for systems where math.h doesn't define M_PI
*/
#undef M_PI
#ifndef M_PI
/*
** static double PI = acos(-1.0);
** #define M_PI (PI)
*/
#define M_PI 3.14159265358979323846
#endif

/* Convert Degrees into Radians */
static double deg2rad(double x){
  return x*M_PI/180.0;
}

/* Convert Radians into Degrees */
static double rad2deg(double x){
  return 180.0*x/M_PI;
}

GEN_MATH_WRAP_DOUBLE_1(rad2degFunc, rad2deg)
GEN_MATH_WRAP_DOUBLE_1(deg2radFunc, deg2rad)

/* constant function that returns the value of PI=3.1415... */
static void piFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  sqlite3_result_double(context, M_PI);
}

/*
** Implements the sqrt function, it has the peculiarity of returning an integer when the
** the argument is an integer.
** Since SQLite isn't strongly typed (almost untyped actually) this is a bit pedantic
*/
static void squareFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  i64 iVal = 0;
  double rVal = 0.0;
  assert( argc==1 );
  switch( sqlite3_value_type(argv[0]) ){
    case SQLITE_INTEGER: {
      iVal = sqlite3_value_int64(argv[0]);
      sqlite3_result_int64(context, iVal*iVal);
      break;
    }
    case SQLITE_NULL: {
      sqlite3_result_null(context);
      break;
    }
    default: {
      rVal = sqlite3_value_double(argv[0]);
      sqlite3_result_double(context, rVal*rVal);
      break;
    }
  }
}

/*
** Wraps the pow math.h function
** When both the base and the exponent are integers the result should be integer
** (see sqrt just before this). Here the result is always double
*/
/* LMH 2007-03-25 Changed to use errno; no pre-checking for errors.  Also removes
  but that was present in the pre-checking that called sqlite3_result_error on
  a non-positive first argument, which is not always an error. */
static void powerFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  double r1 = 0.0;
  double r2 = 0.0;
  double val;

  assert( argc==2 );

  if( sqlite3_value_type(argv[0]) == SQLITE_NULL || sqlite3_value_type(argv[1]) == SQLITE_NULL ){
    sqlite3_result_null(context);
  }else{
    r1 = sqlite3_value_double(argv[0]);
    r2 = sqlite3_value_double(argv[1]);
    errno = 0;
    val = pow(r1,r2);
    if (errno == 0) {
      sqlite3_result_double(context, val);
    } else {
      sqlite3_result_error(context, strerror(errno), errno);
    }
  }
}

/*
** atan2 wrapper
*/
static void atn2Func(sqlite3_context *context, int argc, sqlite3_value **argv){
  double r1 = 0.0;
  double r2 = 0.0;

  assert( argc==2 );

  if( sqlite3_value_type(argv[0]) == SQLITE_NULL || sqlite3_value_type(argv[1]) == SQLITE_NULL ){
    sqlite3_result_null(context);
  }else{
    r1 = sqlite3_value_double(argv[0]);
    r2 = sqlite3_value_double(argv[1]);
    sqlite3_result_double(context, atan2(r1,r2));
  }
}

/*
** Implementation of the sign() function
** return one of 3 possibilities +1,0 or -1 when the argument is respectively
** positive, 0 or negative.
** When the argument is NULL the result is also NULL (completly conventional)
*/
static void signFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  double rVal=0.0;
  i64 iVal=0;
  assert( argc==1 );
  switch( sqlite3_value_type(argv[0]) ){
    case SQLITE_INTEGER: {
      iVal = sqlite3_value_int64(argv[0]);
      iVal = ( iVal > 0) ? 1: ( iVal < 0 ) ? -1: 0;
      sqlite3_result_int64(context, iVal);
      break;
    }
    case SQLITE_NULL: {
      sqlite3_result_null(context);
      break;
    }
    default: {
 /* 2nd change below. Line for abs was: if( rVal<0 ) rVal = rVal * -1.0;  */

      rVal = sqlite3_value_double(argv[0]);
      rVal = ( rVal > 0) ? 1: ( rVal < 0 ) ? -1: 0;
      sqlite3_result_double(context, rVal);
      break;
    }
  }
}


/*
** smallest integer value not less than argument
*/
static void ceilFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  double rVal=0.0;
  assert( argc==1 );
  switch( sqlite3_value_type(argv[0]) ){
    case SQLITE_INTEGER: {
      i64 iVal = sqlite3_value_int64(argv[0]);
      sqlite3_result_int64(context, iVal);
      break;
    }
    case SQLITE_NULL: {
      sqlite3_result_null(context);
      break;
    }
    default: {
      rVal = sqlite3_value_double(argv[0]);
      sqlite3_result_int64(context, (i64) ceil(rVal));
      break;
    }
  }
}

/*
** largest integer value not greater than argument
*/
static void floorFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  double rVal=0.0;
  assert( argc==1 );
  switch( sqlite3_value_type(argv[0]) ){
    case SQLITE_INTEGER: {
      i64 iVal = sqlite3_value_int64(argv[0]);
      sqlite3_result_int64(context, iVal);
      break;
    }
    case SQLITE_NULL: {
      sqlite3_result_null(context);
      break;
    }
    default: {
      rVal = sqlite3_value_double(argv[0]);
      sqlite3_result_int64(context, (i64) floor(rVal));
      break;
    }
  }
}

/*
** Given a string (s) in the first argument and an integer (n) in the second returns the
** string that constains s contatenated n times
*/
static void replicateFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  unsigned char *z;        /* input string */
  unsigned char *zo;       /* result string */
  i64 iCount;              /* times to repeat */
  i64 nLen;                /* length of the input string (no multibyte considerations) */
  i64 nTLen;               /* length of the result string (no multibyte considerations) */
  i64 i=0;

  if( argc!=2 || SQLITE_NULL==sqlite3_value_type(argv[0]) )
    return;

  iCount = sqlite3_value_int64(argv[1]);

  if( iCount<0 ){
    sqlite3_result_error(context, "domain error", -1);
  }else{

    nLen  = sqlite3_value_bytes(argv[0]);
    nTLen = nLen*iCount;
    z=sqlite3_malloc(nTLen+1);
    zo=sqlite3_malloc(nLen+1);
    if (!z || !zo){
      sqlite3_result_error_nomem(context);
      if (z) sqlite3_free(z);
      if (zo) sqlite3_free(zo);
      return;
    }
    strcpy((char*)zo, (char*)sqlite3_value_text(argv[0]));

    for(i=0; i<iCount; ++i){
      strcpy((char*)(z+i*nLen), (char*)zo);
    }

    sqlite3_result_text(context, (char*)z, -1, SQLITE_TRANSIENT);
    sqlite3_free(z);
    sqlite3_free(zo);
  }
}

/*
** Some systems (win32 among others) don't have an isblank function, this will emulate it.
** This function is not UFT-8 safe since it only analyses a byte character.
*/
#ifndef HAVE_ISBLANK
int isblank(char c){
  return( ' '==c || '\t'==c );
}
#endif

static void properFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  const unsigned char *z;     /* input string */
  unsigned char *zo;          /* output string */
  unsigned char *zt;          /* iterator */
  char r;
  int c=1;

  assert( argc==1);
  if( SQLITE_NULL==sqlite3_value_type(argv[0]) ){
    sqlite3_result_null(context);
    return;
  }

  z = sqlite3_value_text(argv[0]);
  zo = (unsigned char *)sqlite3StrDup((char *) z);
  if (!zo) {
    sqlite3_result_error_nomem(context);
    return;
  }
  zt = zo;

  while( (r = *(z++))!=0 ){
    if( isblank(r) ){
      c=1;
    }else{
      if( c==1 ){
        r = toupper(r);
      }else{
        r = tolower(r);
      }
      c=0;
    }
    *(zt++) = r;
  }
  *zt = '\0';

  sqlite3_result_text(context, (char*)zo, -1, SQLITE_TRANSIENT);
  sqlite3_free(zo);
}

/*
** given an input string (s) and an integer (n) adds spaces at the begining of  s
** until it has a length of n characters.
** When s has a length >=n it's a NOP
** padl(NULL) = NULL
*/
static void padlFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  i64 ilen;          /* length to pad to */
  i64 zl;            /* length of the input string (UTF-8 chars) */
  int i = 0;
  const char *zi;    /* input string */
  char *zo;          /* output string */
  char *zt;

  assert( argc==2 );

  if( sqlite3_value_type(argv[0]) == SQLITE_NULL ){
    sqlite3_result_null(context);
  }else{
    zi = (char *)sqlite3_value_text(argv[0]);
    ilen = sqlite3_value_int64(argv[1]);
    /* check domain */
    if(ilen<0){
      sqlite3_result_error(context, "domain error", -1);
      return;
    }
    zl = sqlite3Utf8CharLen(zi, -1);
    if( zl>=ilen ){
      /* string is longer than the requested pad length, return the same string (dup it) */
      zo = sqlite3StrDup(zi);
      if (!zo){
        sqlite3_result_error_nomem(context);
        return;
      }
      sqlite3_result_text(context, zo, -1, SQLITE_TRANSIENT);
    }else{
      zo = sqlite3_malloc(strlen(zi)+ilen-zl+1);
      if (!zo){
        sqlite3_result_error_nomem(context);
        return;
      }
      zt = zo;
      for(i=1; i+zl<=ilen; ++i){
        *(zt++)=' ';
      }
      /* no need to take UTF-8 into consideration here */
      strcpy(zt,zi);
    }
    sqlite3_result_text(context, zo, -1, SQLITE_TRANSIENT);
    sqlite3_free(zo);
  }
}

/*
** given an input string (s) and an integer (n) appends spaces at the end of  s
** until it has a length of n characters.
** When s has a length >=n it's a NOP
** padl(NULL) = NULL
*/
static void padrFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  i64 ilen;          /* length to pad to */
  i64 zl;            /* length of the input string (UTF-8 chars) */
  i64 zll;           /* length of the input string (bytes) */
  int i = 0;
  const char *zi;    /* input string */
  char *zo;          /* output string */
  char *zt;

  assert( argc==2 );

  if( sqlite3_value_type(argv[0]) == SQLITE_NULL ){
    sqlite3_result_null(context);
  }else{
    zi = (char *)sqlite3_value_text(argv[0]);
    ilen = sqlite3_value_int64(argv[1]);
    /* check domain */
    if(ilen<0){
      sqlite3_result_error(context, "domain error", -1);
      return;
    }
    zl = sqlite3Utf8CharLen(zi, -1);
    if( zl>=ilen ){
      /* string is longer than the requested pad length, return the same string (dup it) */
      zo = sqlite3StrDup(zi);
      if (!zo){
        sqlite3_result_error_nomem(context);
        return;
      }
      sqlite3_result_text(context, zo, -1, SQLITE_TRANSIENT);
    }else{
      zll = strlen(zi);
      zo = sqlite3_malloc(zll+ilen-zl+1);
      if (!zo){
        sqlite3_result_error_nomem(context);
        return;
      }
      zt = strcpy(zo,zi)+zll;
      for(i=1; i+zl<=ilen; ++i){
        *(zt++) = ' ';
      }
      *zt = '\0';
    }
    sqlite3_result_text(context, zo, -1, SQLITE_TRANSIENT);
    sqlite3_free(zo);
  }
}

/*
** given an input string (s) and an integer (n) appends spaces at the end of  s
** and adds spaces at the begining of s until it has a length of n characters.
** Tries to add has many characters at the left as at the right.
** When s has a length >=n it's a NOP
** padl(NULL) = NULL
*/
static void padcFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  i64 ilen;           /* length to pad to */
  i64 zl;             /* length of the input string (UTF-8 chars) */
  i64 zll;            /* length of the input string (bytes) */
  int i = 0;
  const char *zi;     /* input string */
  char *zo;           /* output string */
  char *zt;

  assert( argc==2 );

  if( sqlite3_value_type(argv[0]) == SQLITE_NULL ){
    sqlite3_result_null(context);
  }else{
    zi = (char *)sqlite3_value_text(argv[0]);
    ilen = sqlite3_value_int64(argv[1]);
    /* check domain */
    if(ilen<0){
      sqlite3_result_error(context, "domain error", -1);
      return;
    }
    zl = sqlite3Utf8CharLen(zi, -1);
    if( zl>=ilen ){
      /* string is longer than the requested pad length, return the same string (dup it) */
      zo = sqlite3StrDup(zi);
      if (!zo){
        sqlite3_result_error_nomem(context);
        return;
      }
      sqlite3_result_text(context, zo, -1, SQLITE_TRANSIENT);
    }else{
      zll = strlen(zi);
      zo = sqlite3_malloc(zll+ilen-zl+1);
      if (!zo){
        sqlite3_result_error_nomem(context);
        return;
      }
      zt = zo;
      for(i=1; 2*i+zl<=ilen; ++i){
        *(zt++) = ' ';
      }
      strcpy(zt, zi);
      zt+=zll;
      for(; i+zl<=ilen; ++i){
        *(zt++) = ' ';
      }
      *zt = '\0';
    }
    sqlite3_result_text(context, zo, -1, SQLITE_TRANSIENT);
    sqlite3_free(zo);
  }
}

/*
** given 2 string (s1,s2) returns the string s1 with the characters NOT in s2 removed
** assumes strings are UTF-8 encoded
*/
static void strfilterFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  const char *zi1;        /* first parameter string (searched string) */
  const char *zi2;        /* second parameter string (vcontains valid characters) */
  const char *z1;
  const char *z21;
  const char *z22;
  char *zo;               /* output string */
  char *zot;
  int c1 = 0;
  int c2 = 0;

  assert( argc==2 );

  if( sqlite3_value_type(argv[0]) == SQLITE_NULL || sqlite3_value_type(argv[1]) == SQLITE_NULL ){
    sqlite3_result_null(context);
  }else{
    zi1 = (char *)sqlite3_value_text(argv[0]);
    zi2 = (char *)sqlite3_value_text(argv[1]);
    /*
    ** maybe I could allocate less, but that would imply 2 passes, rather waste
    ** (possibly) some memory
    */
    zo = sqlite3_malloc(strlen(zi1)+1);
    if (!zo){
      sqlite3_result_error_nomem(context);
      return;
    }
    zot = zo;
    z1 = zi1;
    while( (c1=sqliteCharVal((unsigned char *)z1))!=0 ){
      z21=zi2;
      while( (c2=sqliteCharVal((unsigned char *)z21))!=0 && c2!=c1 ){
        sqliteNextChar(z21);
      }
      if( c2!=0){
        z22=z21;
        sqliteNextChar(z22);
        strncpy(zot, z21, z22-z21);
        zot+=z22-z21;
      }
      sqliteNextChar(z1);
    }
    *zot = '\0';

    sqlite3_result_text(context, zo, -1, SQLITE_TRANSIENT);
    sqlite3_free(zo);
  }
}

/*
** Given a string z1, retutns the (0 based) index of it's first occurence
** in z2 after the first s characters.
** Returns -1 when there isn't a match.
** updates p to point to the character where the match occured.
** This is an auxiliary function.
*/
static int _substr(const char* z1, const char* z2, int s, const char** p){
  int c = 0;
  int rVal=-1;
  const char* zt1;
  const char* zt2;
  int c1,c2;

  if( '\0'==*z1 ){
    return -1;
  }

  while( (sqliteCharVal((unsigned char *)z2) != 0) && (c++)<s){
    sqliteNextChar(z2);
  }

  c = 0;
  while( (sqliteCharVal((unsigned char *)z2)) != 0 ){
    zt1 = z1;
    zt2 = z2;

    do{
      c1 = sqliteCharVal((unsigned char *)zt1);
      c2 = sqliteCharVal((unsigned char *)zt2);
      sqliteNextChar(zt1);
      sqliteNextChar(zt2);
    }while( c1 == c2 && c1 != 0 && c2 != 0 );

    if( c1 == 0 ){
      rVal = c;
      break;
    }

    sqliteNextChar(z2);
    ++c;
  }
  if(p){
    *p=z2;
  }
  return rVal >=0 ? rVal+s : rVal;
}

/*
** given 2 input strings (s1,s2) and an integer (n) searches from the nth character
** for the string s1. Returns the position where the match occured.
** Characters are counted from 1.
** 0 is returned when no match occurs.
*/

static void charindexFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  const u8 *z1;          /* s1 string */
  u8 *z2;                /* s2 string */
  int s=0;
  int rVal=0;

  assert( argc==3 ||argc==2);

  if( SQLITE_NULL==sqlite3_value_type(argv[0]) || SQLITE_NULL==sqlite3_value_type(argv[1])){
    sqlite3_result_null(context);
    return;
  }

  z1 = sqlite3_value_text(argv[0]);
  if( z1==0 ) return;
  z2 = (u8*) sqlite3_value_text(argv[1]);
  if(argc==3){
    s = sqlite3_value_int(argv[2])-1;
    if(s<0){
      s=0;
    }
  }else{
    s = 0;
  }

  rVal = _substr((char *)z1,(char *)z2,s,NULL);
  sqlite3_result_int(context, rVal+1);
}

/*
** given a string (s) and an integer (n) returns the n leftmost (UTF-8) characters
** if the string has a length<=n or is NULL this function is NOP
*/
static void leftFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  int c=0;
  int cc=0;
  int l=0;
  const unsigned char *z;       /* input string */
  const unsigned char *zt;
  unsigned char *rz;            /* output string */

  assert( argc==2);

  if( SQLITE_NULL==sqlite3_value_type(argv[0]) || SQLITE_NULL==sqlite3_value_type(argv[1])){
    sqlite3_result_null(context);
    return;
  }

  z  = sqlite3_value_text(argv[0]);
  l  = sqlite3_value_int(argv[1]);
  zt = z;

  while( sqliteCharVal(zt) && c++<l)
    sqliteNextChar(zt);

  cc=zt-z;

  rz = sqlite3_malloc(zt-z+1);
  if (!rz){
    sqlite3_result_error_nomem(context);
    return;
  }
  strncpy((char*) rz, (char*) z, zt-z);
  *(rz+cc) = '\0';
  sqlite3_result_text(context, (char*)rz, -1, SQLITE_TRANSIENT);
  sqlite3_free(rz);
}

/*
** given a string (s) and an integer (n) returns the n rightmost (UTF-8) characters
** if the string has a length<=n or is NULL this function is NOP
*/
static void rightFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  int l=0;
  int c=0;
  int cc=0;
  const char *z;
  const char *zt;
  const char *ze;
  char *rz;

  assert( argc==2);

  if( SQLITE_NULL == sqlite3_value_type(argv[0]) || SQLITE_NULL == sqlite3_value_type(argv[1])){
    sqlite3_result_null(context);
    return;
  }

  z  = (char *)sqlite3_value_text(argv[0]);
  l  = sqlite3_value_int(argv[1]);
  zt = z;

  while( sqliteCharVal((unsigned char *)zt)!=0){
    sqliteNextChar(zt);
    ++c;
  }

  ze = zt;
  zt = z;

  cc=c-l;
  if(cc<0)
    cc=0;

  while( cc-- > 0 ){
    sqliteNextChar(zt);
  }

  rz = sqlite3_malloc(ze-zt+1);
  if (!rz){
    sqlite3_result_error_nomem(context);
    return;
  }
  strcpy((char*) rz, (char*) (zt));
  sqlite3_result_text(context, (char*)rz, -1, SQLITE_TRANSIENT);
  sqlite3_free(rz);
}

#ifndef HAVE_TRIM
/*
** removes the whitespaces at the begining of a string.
*/
const char* ltrim(const char* s){
  while( *s==' ' )
    ++s;
  return s;
}

/*
** removes the whitespaces at the end of a string.
** !mutates the input string!
*/
void rtrim(char* s){
  char* ss = s+strlen(s)-1;
  while( ss>=s && *ss==' ' )
    --ss;
  *(ss+1)='\0';
}

/*
**  Removes the whitespace at the begining of a string
*/
static void ltrimFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  const char *z;

  assert( argc==1);

  if( SQLITE_NULL==sqlite3_value_type(argv[0]) ){
    sqlite3_result_null(context);
    return;
  }
  z = sqlite3_value_text(argv[0]);
  sqlite3_result_text(context, ltrim(z), -1, SQLITE_TRANSIENT);
}

/*
**  Removes the whitespace at the end of a string
*/
static void rtrimFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  const char *z;
  char *rz;
  /* try not to change data in argv */

  assert( argc==1);

  if( SQLITE_NULL==sqlite3_value_type(argv[0]) ){
    sqlite3_result_null(context);
    return;
  }
  z = sqlite3_value_text(argv[0]);
  rz = sqlite3StrDup(z);
  rtrim(rz);
  sqlite3_result_text(context, rz, -1, SQLITE_TRANSIENT);
  sqlite3_free(rz);
}

/*
**  Removes the whitespace at the begining and end of a string
*/
static void trimFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  const char *z;
  char *rz;
  /* try not to change data in argv */

  assert( argc==1);

  if( SQLITE_NULL==sqlite3_value_type(argv[0]) ){
    sqlite3_result_null(context);
    return;
  }
  z = sqlite3_value_text(argv[0]);
  rz = sqlite3StrDup(z);
  rtrim(rz);
  sqlite3_result_text(context, ltrim(rz), -1, SQLITE_TRANSIENT);
  sqlite3_free(rz);
}
#endif

/*
** given a pointer to a string s1, the length of that string (l1), a new string (s2)
** and it's length (l2) appends s2 to s1.
** All lengths in bytes.
** This is just an auxiliary function
*/
// static void _append(char **s1, int l1, const char *s2, int l2){
//   *s1 = realloc(*s1, (l1+l2+1)*sizeof(char));
//   strncpy((*s1)+l1, s2, l2);
//   *(*(s1)+l1+l2) = '\0';
// }

#ifndef HAVE_TRIM

/*
** given strings s, s1 and s2 replaces occurrences of s1 in s by s2
*/
static void replaceFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  const char *z1;     /* string s (first parameter) */
  const char *z2;     /* string s1 (second parameter) string to look for */
  const char *z3;     /* string s2 (third parameter) string to replace occurrences of s1 with */
  int lz1;
  int lz2;
  int lz3;
  int lzo=0;
  char *zo=0;
  int ret=0;
  const char *zt1;
  const char *zt2;

  assert( 3==argc );

  if( SQLITE_NULL==sqlite3_value_type(argv[0]) ){
    sqlite3_result_null(context);
    return;
  }

  z1 = sqlite3_value_text(argv[0]);
  z2 = sqlite3_value_text(argv[1]);
  z3 = sqlite3_value_text(argv[2]);
  /* handle possible null values */
  if( 0==z2 ){
    z2="";
  }
  if( 0==z3 ){
    z3="";
  }

  lz1 = strlen(z1);
  lz2 = strlen(z2);
  lz3 = strlen(z3);

#if 0
  /* special case when z2 is empty (or null) nothing will be changed */
  if( 0==lz2 ){
    sqlite3_result_text(context, z1, -1, SQLITE_TRANSIENT);
    return;
  }
#endif

  zt1=z1;
  zt2=z1;

  while(1){
    ret=_substr(z2,zt1 , 0, &zt2);

    if( ret<0 )
      break;

    _append(&zo, lzo, zt1, zt2-zt1);
    lzo+=zt2-zt1;
    _append(&zo, lzo, z3, lz3);
    lzo+=lz3;

    zt1=zt2+lz2;
  }
  _append(&zo, lzo, zt1, lz1-(zt1-z1));
  sqlite3_result_text(context, zo, -1, SQLITE_TRANSIENT);
  sqlite3_free(zo);
}
#endif

/*
** given a string returns the same string but with the characters in reverse order
*/
static void reverseFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  const char *z;
  const char *zt;
  char *rz;
  char *rzt;
  int l = 0;
  int i = 0;

  assert( 1==argc );

  if( SQLITE_NULL==sqlite3_value_type(argv[0]) ){
    sqlite3_result_null(context);
    return;
  }
  z = (char *)sqlite3_value_text(argv[0]);
  l = strlen(z);
  rz = sqlite3_malloc(l+1);
  if (!rz){
    sqlite3_result_error_nomem(context);
    return;
  }
  rzt = rz+l;
  *(rzt--) = '\0';

  zt=z;
  while( sqliteCharVal((unsigned char *)zt)!=0 ){
    z=zt;
    sqliteNextChar(zt);
    for(i=1; zt-i>=z; ++i){
      *(rzt--)=*(zt-i);
    }
  }

  sqlite3_result_text(context, rz, -1, SQLITE_TRANSIENT);
  sqlite3_free(rz);
}

/*
** An instance of the following structure holds the context of a
** stdev() or variance() aggregate computation.
** implementaion of http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Algorithm_II
** less prone to rounding errors
*/
typedef struct StdevCtx StdevCtx;
struct StdevCtx {
  double rM;
  double rS;
  i64 cnt;          /* number of elements */
};

/*
** An instance of the following structure holds the context of a
** mode() or median() aggregate computation.
** Depends on structures defined in map.c (see map & map)
** These aggregate functions only work for integers and floats although
** they could be made to work for strings. This is usually considered meaningless.
** Only usuall order (for median), no use of collation functions (would this even make sense?)
*/
typedef struct ModeCtx ModeCtx;
struct ModeCtx {
  i64 riM;            /* integer value found so far */
  double rdM;         /* double value found so far */
  i64 cnt;            /* number of elements so far */
  double pcnt;        /* number of elements smaller than a percentile */
  i64 mcnt;           /* maximum number of occurrences (for mode) */
  i64 mn;             /* number of occurrences (for mode and percentiles) */
  i64 is_double;      /* whether the computation is being done for doubles (>0) or integers (=0) */
  map* m;             /* map structure used for the computation */
  int done;           /* whether the answer has been found */
};

/*
** called for each value received during a calculation of stdev or variance
*/
static void varianceStep(sqlite3_context *context, int argc, sqlite3_value **argv){
  StdevCtx *p;

  double delta;
  double x;

  assert( argc==1 );
  p = sqlite3_aggregate_context(context, sizeof(*p));
  /* only consider non-null values */
  if( SQLITE_NULL != sqlite3_value_numeric_type(argv[0]) ){
    p->cnt++;
    x = sqlite3_value_double(argv[0]);
    delta = (x-p->rM);
    p->rM += delta/p->cnt;
    p->rS += delta*(x-p->rM);
  }
}

/*
** called for each value received during a calculation of mode of median
*/
static void modeStep(sqlite3_context *context, int argc, sqlite3_value **argv){
  ModeCtx *p;
  i64 xi=0;
  double xd=0.0;
  i64 *iptr;
  double *dptr;
  int type;

  assert( argc==1 );
  type = sqlite3_value_numeric_type(argv[0]);

  if( type == SQLITE_NULL)
    return;

  p = sqlite3_aggregate_context(context, sizeof(*p));

  if( 0==(p->m) ){
    p->m = calloc(1, sizeof(map));
    if( type==SQLITE_INTEGER ){
      /* map will be used for integers */
      *(p->m) = map_make(int_cmp);
      p->is_double = 0;
    }else{
      p->is_double = 1;
      /* map will be used for doubles */
      *(p->m) = map_make(double_cmp);
    }
  }

  ++(p->cnt);

  if( 0==p->is_double ){
    xi = sqlite3_value_int64(argv[0]);
    iptr = (i64*)calloc(1,sizeof(i64));
    *iptr = xi;
    map_insert(p->m, iptr);
  }else{
    xd = sqlite3_value_double(argv[0]);
    dptr = (double*)calloc(1,sizeof(double));
    *dptr = xd;
    map_insert(p->m, dptr);
  }
}

/*
**  Auxiliary function that iterates all elements in a map and finds the mode
**  (most frequent value)
*/
static void modeIterate(void* e, i64 c, void* pp){
  i64 ei;
  double ed;
  ModeCtx *p = (ModeCtx*)pp;

  if( 0==p->is_double ){
    ei = *(int*)(e);

	if( p->mcnt==c ){
      ++p->mn;
    }else if( p->mcnt<c ){
      p->riM = ei;
      p->mcnt = c;
	  p->mn=1;
    }
  }else{
    ed = *(double*)(e);

	if( p->mcnt==c ){
      ++p->mn;
    }else if(p->mcnt<c){
      p->rdM = ed;
      p->mcnt = c;
	  p->mn=1;
    }
  }
}

/*
**  Auxiliary function that iterates all elements in a map and finds the median
**  (the value such that the number of elements smaller is equal the the number of
**  elements larger)
*/
static void medianIterate(void* e, i64 c, void* pp){
  i64 ei;
  double ed;
  double iL;
  double iR;
  int il;
  int ir;
  ModeCtx *p = (ModeCtx*)pp;

  if(p->done>0)
    return;

  iL = p->pcnt;
  iR = p->cnt - p->pcnt;
  il = p->mcnt + c;
  ir = p->cnt - p->mcnt;

  if( il >= iL ){
    if( ir >= iR ){
    ++p->mn;
      if( 0==p->is_double ){
        ei = *(int*)(e);
        p->riM += ei;
      }else{
        ed = *(double*)(e);
        p->rdM += ed;
      }
    }else{
      p->done=1;
    }
  }
  p->mcnt+=c;
}

/*
** Returns the mode value
*/
static void modeFinalize(sqlite3_context *context){
  ModeCtx *p;
  p = sqlite3_aggregate_context(context, 0);
  if( p && p->m ){
    map_iterate(p->m, modeIterate, p);
    map_destroy(p->m);
    free(p->m);

    if( 1==p->mn ){
      if( 0==p->is_double )
        sqlite3_result_int64(context, p->riM);
      else
        sqlite3_result_double(context, p->rdM);
    }
  }
}

/*
** auxiliary function for percentiles
*/
static void _medianFinalize(sqlite3_context *context){
  ModeCtx *p;
  p = (ModeCtx*) sqlite3_aggregate_context(context, 0);
  if( p && p->m ){
    p->done=0;
    map_iterate(p->m, medianIterate, p);
    map_destroy(p->m);
    free(p->m);

    if( 0==p->is_double )
      if( 1==p->mn )
      	sqlite3_result_int64(context, p->riM);
      else
      	sqlite3_result_double(context, p->riM*1.0/p->mn);
    else
      sqlite3_result_double(context, p->rdM/p->mn);
  }
}

/*
** Returns the median value
*/
static void medianFinalize(sqlite3_context *context){
  ModeCtx *p;
  p = (ModeCtx*) sqlite3_aggregate_context(context, 0);
  if( p!=0 ){
    p->pcnt = (p->cnt)/2.0;
    _medianFinalize(context);
  }
}

/*
** Returns the lower_quartile value
*/
static void lower_quartileFinalize(sqlite3_context *context){
  ModeCtx *p;
  p = (ModeCtx*) sqlite3_aggregate_context(context, 0);
  if( p!=0 ){
    p->pcnt = (p->cnt)/4.0;
    _medianFinalize(context);
  }
}

/*
** Returns the upper_quartile value
*/
static void upper_quartileFinalize(sqlite3_context *context){
  ModeCtx *p;
  p = (ModeCtx*) sqlite3_aggregate_context(context, 0);
  if( p!=0 ){
    p->pcnt = (p->cnt)*3/4.0;
    _medianFinalize(context);
  }
}

/*
** Returns the stdev value
*/
static void stdevFinalize(sqlite3_context *context){
  StdevCtx *p;
  p = sqlite3_aggregate_context(context, 0);
  if( p && p->cnt>1 ){
    sqlite3_result_double(context, sqrt(p->rS/(p->cnt-1)));
  }else{
    sqlite3_result_null(context);
  }
}

/*
** Returns the variance value
*/
static void varianceFinalize(sqlite3_context *context){
  StdevCtx *p;
  p = sqlite3_aggregate_context(context, 0);
  if( p && p->cnt>1 ){
    sqlite3_result_double(context, p->rS/(p->cnt-1));
  }else{
    sqlite3_result_null(context);
  }
}

#ifdef SQLITE_SOUNDEX

/* relicoder factored code */
/*
** Calculates the soundex value of a string
*/

static void soundex(const u8 *zIn, char *zResult){
  int i, j;
  static const unsigned char iCode[] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 1, 2, 3, 0, 1, 2, 0, 0, 2, 2, 4, 5, 5, 0,
    1, 2, 6, 2, 3, 0, 1, 0, 2, 0, 2, 0, 0, 0, 0, 0,
    0, 0, 1, 2, 3, 0, 1, 2, 0, 0, 2, 2, 4, 5, 5, 0,
    1, 2, 6, 2, 3, 0, 1, 0, 2, 0, 2, 0, 0, 0, 0, 0,
  };

  for(i=0; zIn[i] && !isalpha(zIn[i]); i++){}
  if( zIn[i] ){
    zResult[0] = toupper(zIn[i]);
    for(j=1; j<4 && zIn[i]; i++){
      int code = iCode[zIn[i]&0x7f];
      if( code>0 ){
        zResult[j++] = code + '0';
      }
    }
    while( j<4 ){
      zResult[j++] = '0';
    }
    zResult[j] = 0;
  }else{
    strcpy(zResult, "?000");
  }
}

/*
** computes the number of different characters between the soundex value fo 2 strings
*/
static void differenceFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  char zResult1[8];
  char zResult2[8];
  char *zR1 = zResult1;
  char *zR2 = zResult2;
  int rVal = 0;
  int i = 0;
  const u8 *zIn1;
  const u8 *zIn2;

  assert( argc==2 );

  if( sqlite3_value_type(argv[0])==SQLITE_NULL || sqlite3_value_type(argv[1])==SQLITE_NULL ){
    sqlite3_result_null(context);
    return;
  }

  zIn1 = (u8*)sqlite3_value_text(argv[0]);
  zIn2 = (u8*)sqlite3_value_text(argv[1]);

  soundex(zIn1, zR1);
  soundex(zIn2, zR2);

  for(i=0; i<4; ++i){
    if( sqliteCharVal((unsigned char *)zR1)==sqliteCharVal((unsigned char *)zR2) )
      ++rVal;
    sqliteNextChar(zR1);
    sqliteNextChar(zR2);
  }
  sqlite3_result_int(context, rVal);
}
#endif

/*
 ** The following #defines change the names of some functions implemented in
 ** this file to prevent name collisions with C-library functions of the
 ** same name.
 */
#define re_match   sqlite3re_match
#define re_compile sqlite3re_compile
#define re_free    sqlite3re_free

/* The end-of-input character */
#define RE_EOF            0    /* End of input */

/* The NFA is implemented as sequence of opcodes taken from the following
** set.  Each opcode has a single integer argument.
*/
#define RE_OP_MATCH       1    /* Match the one character in the argument */
#define RE_OP_ANY         2    /* Match any one character.  (Implements ".") */
#define RE_OP_ANYSTAR     3    /* Special optimized version of .* */
#define RE_OP_FORK        4    /* Continue to both next and opcode at iArg */
#define RE_OP_GOTO        5    /* Jump to opcode at iArg */
#define RE_OP_ACCEPT      6    /* Halt and indicate a successful match */
#define RE_OP_CC_INC      7    /* Beginning of a [...] character class */
#define RE_OP_CC_EXC      8    /* Beginning of a [^...] character class */
#define RE_OP_CC_VALUE    9    /* Single value in a character class */
#define RE_OP_CC_RANGE   10    /* Range of values in a character class */
#define RE_OP_WORD       11    /* Perl word character [A-Za-z0-9_] */
#define RE_OP_NOTWORD    12    /* Not a perl word character */
#define RE_OP_DIGIT      13    /* digit:  [0-9] */
#define RE_OP_NOTDIGIT   14    /* Not a digit */
#define RE_OP_SPACE      15    /* space:  [ \t\n\r\v\f] */
#define RE_OP_NOTSPACE   16    /* Not a digit */
#define RE_OP_BOUNDARY   17    /* Boundary between word and non-word */

/* Each opcode is a "state" in the NFA */
typedef unsigned short ReStateNumber;

/* Because this is an NFA and not a DFA, multiple states can be active at
** once.  An instance of the following object records all active states in
** the NFA.  The implementation is optimized for the common case where the
** number of actives states is small.
*/
typedef struct ReStateSet {
  unsigned nState;            /* Number of current states */
ReStateNumber *aState;      /* Current states */
} ReStateSet;

/* An input string read one character at a time.
*/
typedef struct ReInput ReInput;
struct ReInput {
  const unsigned char *z;  /* All text */
int i;                   /* Next byte to read */
int mx;                  /* EOF when i>=mx */
};

/* A compiled NFA (or an NFA that is in the process of being compiled) is
** an instance of the following object.
*/
typedef struct ReCompiled ReCompiled;
struct ReCompiled {
  ReInput sIn;                /* Regular expression text */
const char *zErr;           /* Error message to return */
char *aOp;                  /* Operators for the virtual machine */
int *aArg;                  /* Arguments to each operator */
unsigned (*xNextChar)(ReInput*);  /* Next character function */
unsigned char zInit[12];    /* Initial text to match */
int nInit;                  /* Number of characters in zInit */
unsigned nState;            /* Number of entries in aOp[] and aArg[] */
unsigned nAlloc;            /* Slots allocated for aOp[] and aArg[] */
};

/* Add a state to the given state set if it is not already there */
static void re_add_state(ReStateSet *pSet, int newState){
  unsigned i;
  for(i=0; i<pSet->nState; i++) if( pSet->aState[i]==newState ) return;
  pSet->aState[pSet->nState++] = (ReStateNumber)newState;
}

/* Extract the next unicode character from *pzIn and return it.  Advance
** *pzIn to the first byte past the end of the character returned.  To
** be clear:  this routine converts utf8 to unicode.  This routine is
** optimized for the common case where the next character is a single byte.
*/
static unsigned re_next_char(ReInput *p){
  unsigned c;
  if( p->i>=p->mx ) return 0;
  c = p->z[p->i++];
  if( c>=0x80 ){
    if( (c&0xe0)==0xc0 && p->i<p->mx && (p->z[p->i]&0xc0)==0x80 ){
      c = (c&0x1f)<<6 | (p->z[p->i++]&0x3f);
      if( c<0x80 ) c = 0xfffd;
    }else if( (c&0xf0)==0xe0 && p->i+1<p->mx && (p->z[p->i]&0xc0)==0x80
                && (p->z[p->i+1]&0xc0)==0x80 ){
      c = (c&0x0f)<<12 | ((p->z[p->i]&0x3f)<<6) | (p->z[p->i+1]&0x3f);
      p->i += 2;
      if( c<=0x3ff || (c>=0xd800 && c<=0xdfff) ) c = 0xfffd;
    }else if( (c&0xf8)==0xf0 && p->i+3<p->mx && (p->z[p->i]&0xc0)==0x80
                && (p->z[p->i+1]&0xc0)==0x80 && (p->z[p->i+2]&0xc0)==0x80 ){
      c = (c&0x07)<<18 | ((p->z[p->i]&0x3f)<<12) | ((p->z[p->i+1]&0x3f)<<6)
      | (p->z[p->i+2]&0x3f);
      p->i += 3;
      if( c<=0xffff || c>0x10ffff ) c = 0xfffd;
    }else{
      c = 0xfffd;
    }
  }
  return c;
}
static unsigned re_next_char_nocase(ReInput *p){
  unsigned c = re_next_char(p);
  if( c>='A' && c<='Z' ) c += 'a' - 'A';
  return c;
}

/* Return true if c is a perl "word" character:  [A-Za-z0-9_] */
static int re_word_char(int c){
  return (c>='0' && c<='9') || (c>='a' && c<='z')
  || (c>='A' && c<='Z') || c=='_';
}

/* Return true if c is a "digit" character:  [0-9] */
static int re_digit_char(int c){
  return (c>='0' && c<='9');
}

/* Return true if c is a perl "space" character:  [ \t\r\n\v\f] */
static int re_space_char(int c){
  return c==' ' || c=='\t' || c=='\n' || c=='\r' || c=='\v' || c=='\f';
}

/* Run a compiled regular expression on the zero-terminated input
** string zIn[].  Return true on a match and false if there is no match.
*/
static int re_match(ReCompiled *pRe, const unsigned char *zIn, int nIn){
  ReStateSet aStateSet[2], *pThis, *pNext;
  ReStateNumber aSpace[100];
  ReStateNumber *pToFree;
  unsigned int i = 0;
  unsigned int iSwap = 0;
  int c = RE_EOF+1;
  int cPrev = 0;
  int rc = 0;
  ReInput in;

  in.z = zIn;
  in.i = 0;
  in.mx = nIn>=0 ? nIn : (int)strlen((char const*)zIn);

  /* Look for the initial prefix match, if there is one. */
  if( pRe->nInit ){
    unsigned char x = pRe->zInit[0];
    while( in.i+pRe->nInit<=in.mx
             && (zIn[in.i]!=x ||
               strncmp((const char*)zIn+in.i, (const char*)pRe->zInit, pRe->nInit)!=0)
    ){
      in.i++;
    }
    if( in.i+pRe->nInit>in.mx ) return 0;
  }

  if( pRe->nState<=(sizeof(aSpace)/(sizeof(aSpace[0])*2)) ){
    pToFree = 0;
    aStateSet[0].aState = aSpace;
  }else{
    pToFree = sqlite3_malloc( sizeof(ReStateNumber)*2*pRe->nState );
    if( pToFree==0 ) return -1;
    aStateSet[0].aState = pToFree;
  }
  aStateSet[1].aState = &aStateSet[0].aState[pRe->nState];
  pNext = &aStateSet[1];
  pNext->nState = 0;
  re_add_state(pNext, 0);
  while( c!=RE_EOF && pNext->nState>0 ){
    cPrev = c;
    c = pRe->xNextChar(&in);
    pThis = pNext;
    pNext = &aStateSet[iSwap];
    iSwap = 1 - iSwap;
    pNext->nState = 0;
    for(i=0; i<pThis->nState; i++){
      int x = pThis->aState[i];
      switch( pRe->aOp[x] ){
      case RE_OP_MATCH: {
        if( pRe->aArg[x]==c ) re_add_state(pNext, x+1);
        break;
      }
      case RE_OP_ANY: {
        re_add_state(pNext, x+1);
        break;
      }
      case RE_OP_WORD: {
        if( re_word_char(c) ) re_add_state(pNext, x+1);
        break;
      }
      case RE_OP_NOTWORD: {
        if( !re_word_char(c) ) re_add_state(pNext, x+1);
        break;
      }
      case RE_OP_DIGIT: {
        if( re_digit_char(c) ) re_add_state(pNext, x+1);
        break;
      }
      case RE_OP_NOTDIGIT: {
        if( !re_digit_char(c) ) re_add_state(pNext, x+1);
        break;
      }
      case RE_OP_SPACE: {
        if( re_space_char(c) ) re_add_state(pNext, x+1);
        break;
      }
      case RE_OP_NOTSPACE: {
        if( !re_space_char(c) ) re_add_state(pNext, x+1);
        break;
      }
      case RE_OP_BOUNDARY: {
        if( re_word_char(c)!=re_word_char(cPrev) ) re_add_state(pThis, x+1);
        break;
      }
      case RE_OP_ANYSTAR: {
        re_add_state(pNext, x);
        re_add_state(pThis, x+1);
        break;
      }
      case RE_OP_FORK: {
        re_add_state(pThis, x+pRe->aArg[x]);
        re_add_state(pThis, x+1);
        break;
      }
      case RE_OP_GOTO: {
        re_add_state(pThis, x+pRe->aArg[x]);
        break;
      }
      case RE_OP_ACCEPT: {
        rc = 1;
        goto re_match_end;
      }
      case RE_OP_CC_INC:
      case RE_OP_CC_EXC: {
        int j = 1;
        int n = pRe->aArg[x];
        int hit = 0;
        for(j=1; j>0 && j<n; j++){
          if( pRe->aOp[x+j]==RE_OP_CC_VALUE ){
            if( pRe->aArg[x+j]==c ){
              hit = 1;
              j = -1;
            }
          }else{
            if( pRe->aArg[x+j]<=c && pRe->aArg[x+j+1]>=c ){
              hit = 1;
              j = -1;
            }else{
              j++;
            }
          }
        }
        if( pRe->aOp[x]==RE_OP_CC_EXC ) hit = !hit;
        if( hit ) re_add_state(pNext, x+n);
        break;
      }
      }
    }
  }
  for(i=0; i<pNext->nState; i++){
    if( pRe->aOp[pNext->aState[i]]==RE_OP_ACCEPT ){ rc = 1; break; }
  }
  re_match_end:
    sqlite3_free(pToFree);
  return rc;
}

/* Resize the opcode and argument arrays for an RE under construction.
*/
static int re_resize(ReCompiled *p, int N){
  char *aOp;
  int *aArg;
  aOp = sqlite3_realloc(p->aOp, N*sizeof(p->aOp[0]));
  if( aOp==0 ) return 1;
  p->aOp = aOp;
  aArg = sqlite3_realloc(p->aArg, N*sizeof(p->aArg[0]));
  if( aArg==0 ) return 1;
  p->aArg = aArg;
  p->nAlloc = N;
  return 0;
}

/* Insert a new opcode and argument into an RE under construction.  The
** insertion point is just prior to existing opcode iBefore.
*/
static int re_insert(ReCompiled *p, int iBefore, int op, int arg){
  int i;
  if( p->nAlloc<=p->nState && re_resize(p, p->nAlloc*2) ) return 0;
  for(i=p->nState; i>iBefore; i--){
    p->aOp[i] = p->aOp[i-1];
    p->aArg[i] = p->aArg[i-1];
  }
  p->nState++;
  p->aOp[iBefore] = (char)op;
  p->aArg[iBefore] = arg;
  return iBefore;
}

/* Append a new opcode and argument to the end of the RE under construction.
*/
static int re_append(ReCompiled *p, int op, int arg){
  return re_insert(p, p->nState, op, arg);
}

/* Make a copy of N opcodes starting at iStart onto the end of the RE
** under construction.
*/
static void re_copy(ReCompiled *p, int iStart, int N){
  if( p->nState+N>=p->nAlloc && re_resize(p, p->nAlloc*2+N) ) return;
  memcpy(&p->aOp[p->nState], &p->aOp[iStart], N*sizeof(p->aOp[0]));
  memcpy(&p->aArg[p->nState], &p->aArg[iStart], N*sizeof(p->aArg[0]));
  p->nState += N;
}

/* Return true if c is a hexadecimal digit character:  [0-9a-fA-F]
** If c is a hex digit, also set *pV = (*pV)*16 + valueof(c).  If
** c is not a hex digit *pV is unchanged.
*/
static int re_hex(int c, int *pV){
  if( c>='0' && c<='9' ){
    c -= '0';
  }else if( c>='a' && c<='f' ){
    c -= 'a' - 10;
  }else if( c>='A' && c<='F' ){
    c -= 'A' - 10;
  }else{
    return 0;
  }
  *pV = (*pV)*16 + (c & 0xff);
  return 1;
}

/* A backslash character has been seen, read the next character and
** return its interpretation.
*/
static unsigned re_esc_char(ReCompiled *p){
  static const char zEsc[] = "afnrtv\\()*.+?[$^{|}]";
  static const char zTrans[] = "\a\f\n\r\t\v";
  int i, v = 0;
  char c;
  if( p->sIn.i>=p->sIn.mx ) return 0;
  c = p->sIn.z[p->sIn.i];
  if( c=='u' && p->sIn.i+4<p->sIn.mx ){
    const unsigned char *zIn = p->sIn.z + p->sIn.i;
    if( re_hex(zIn[1],&v)
          && re_hex(zIn[2],&v)
          && re_hex(zIn[3],&v)
          && re_hex(zIn[4],&v)
    ){
      p->sIn.i += 5;
      return v;
    }
  }
  if( c=='x' && p->sIn.i+2<p->sIn.mx ){
    const unsigned char *zIn = p->sIn.z + p->sIn.i;
    if( re_hex(zIn[1],&v)
          && re_hex(zIn[2],&v)
    ){
      p->sIn.i += 3;
      return v;
    }
  }
  for(i=0; zEsc[i] && zEsc[i]!=c; i++){}
  if( zEsc[i] ){
    if( i<6 ) c = zTrans[i];
    p->sIn.i++;
  }else{
    p->zErr = "unknown \\ escape";
  }
  return c;
}

/* Forward declaration */
static const char *re_subcompile_string(ReCompiled*);

/* Peek at the next byte of input */
static unsigned char rePeek(ReCompiled *p){
  return p->sIn.i<p->sIn.mx ? p->sIn.z[p->sIn.i] : 0;
}

/* Compile RE text into a sequence of opcodes.  Continue up to the
** first unmatched ")" character, then return.  If an error is found,
** return a pointer to the error message string.
*/
static const char *re_subcompile_re(ReCompiled *p){
  const char *zErr;
  int iStart, iEnd, iGoto;
  iStart = p->nState;
  zErr = re_subcompile_string(p);
  if( zErr ) return zErr;
  while( rePeek(p)=='|' ){
    iEnd = p->nState;
    re_insert(p, iStart, RE_OP_FORK, iEnd + 2 - iStart);
    iGoto = re_append(p, RE_OP_GOTO, 0);
    p->sIn.i++;
    zErr = re_subcompile_string(p);
    if( zErr ) return zErr;
    p->aArg[iGoto] = p->nState - iGoto;
  }
  return 0;
}

/* Compile an element of regular expression text (anything that can be
** an operand to the "|" operator).  Return NULL on success or a pointer
** to the error message if there is a problem.
*/
static const char *re_subcompile_string(ReCompiled *p){
  int iPrev = -1;
  int iStart;
  unsigned c;
  const char *zErr;
  while( (c = p->xNextChar(&p->sIn))!=0 ){
    iStart = p->nState;
    switch( c ){
    case '|':
    case '$':
    case ')': {
      p->sIn.i--;
      return 0;
    }
    case '(': {
      zErr = re_subcompile_re(p);
      if( zErr ) return zErr;
      if( rePeek(p)!=')' ) return "unmatched '('";
      p->sIn.i++;
      break;
    }
    case '.': {
      if( rePeek(p)=='*' ){
      re_append(p, RE_OP_ANYSTAR, 0);
      p->sIn.i++;
    }else{
      re_append(p, RE_OP_ANY, 0);
    }
    break;
    }
    case '*': {
      if( iPrev<0 ) return "'*' without operand";
      re_insert(p, iPrev, RE_OP_GOTO, p->nState - iPrev + 1);
      re_append(p, RE_OP_FORK, iPrev - p->nState + 1);
      break;
    }
    case '+': {
      if( iPrev<0 ) return "'+' without operand";
      re_append(p, RE_OP_FORK, iPrev - p->nState);
      break;
    }
    case '?': {
      if( iPrev<0 ) return "'?' without operand";
      re_insert(p, iPrev, RE_OP_FORK, p->nState - iPrev+1);
      break;
    }
    case '{': {
      int m = 0, n = 0;
      int sz, j;
      if( iPrev<0 ) return "'{m,n}' without operand";
      while( (c=rePeek(p))>='0' && c<='9' ){ m = m*10 + c - '0'; p->sIn.i++; }
      n = m;
      if( c==',' ){
        p->sIn.i++;
        n = 0;
        while( (c=rePeek(p))>='0' && c<='9' ){ n = n*10 + c-'0'; p->sIn.i++; }
      }
      if( c!='}' ) return "unmatched '{'";
      if( n>0 && n<m ) return "n less than m in '{m,n}'";
      p->sIn.i++;
      sz = p->nState - iPrev;
      if( m==0 ){
        if( n==0 ) return "both m and n are zero in '{m,n}'";
        re_insert(p, iPrev, RE_OP_FORK, sz+1);
        n--;
      }else{
        for(j=1; j<m; j++) re_copy(p, iPrev, sz);
      }
      for(j=m; j<n; j++){
        re_append(p, RE_OP_FORK, sz+1);
        re_copy(p, iPrev, sz);
      }
      if( n==0 && m>0 ){
        re_append(p, RE_OP_FORK, -sz);
      }
      break;
    }
    case '[': {
      int iFirst = p->nState;
      if( rePeek(p)=='^' ){
        re_append(p, RE_OP_CC_EXC, 0);
        p->sIn.i++;
      }else{
        re_append(p, RE_OP_CC_INC, 0);
      }
      while( (c = p->xNextChar(&p->sIn))!=0 ){
        if( c=='[' && rePeek(p)==':' ){
          return "POSIX character classes not supported";
        }
        if( c=='\\' ) c = re_esc_char(p);
        if( rePeek(p)=='-' ){
          re_append(p, RE_OP_CC_RANGE, c);
          p->sIn.i++;
          c = p->xNextChar(&p->sIn);
          if( c=='\\' ) c = re_esc_char(p);
          re_append(p, RE_OP_CC_RANGE, c);
        }else{
          re_append(p, RE_OP_CC_VALUE, c);
        }
        if( rePeek(p)==']' ){ p->sIn.i++; break; }
      }
      if( c==0 ) return "unclosed '['";
      p->aArg[iFirst] = p->nState - iFirst;
      break;
    }
    case '\\': {
      int specialOp = 0;
      switch( rePeek(p) ){
      case 'b': specialOp = RE_OP_BOUNDARY;   break;
      case 'd': specialOp = RE_OP_DIGIT;      break;
      case 'D': specialOp = RE_OP_NOTDIGIT;   break;
      case 's': specialOp = RE_OP_SPACE;      break;
      case 'S': specialOp = RE_OP_NOTSPACE;   break;
      case 'w': specialOp = RE_OP_WORD;       break;
      case 'W': specialOp = RE_OP_NOTWORD;    break;
      }
      if( specialOp ){
        p->sIn.i++;
        re_append(p, specialOp, 0);
      }else{
        c = re_esc_char(p);
        re_append(p, RE_OP_MATCH, c);
      }
      break;
    }
    default: {
      re_append(p, RE_OP_MATCH, c);
      break;
    }
    }
    iPrev = iStart;
  }
  return 0;
}

/* Free and reclaim all the memory used by a previously compiled
** regular expression.  Applications should invoke this routine once
** for every call to re_compile() to avoid memory leaks.
*/
void re_free(ReCompiled *pRe){
  if( pRe ){
    sqlite3_free(pRe->aOp);
    sqlite3_free(pRe->aArg);
    sqlite3_free(pRe);
  }
}

/*
** Compile a textual regular expression in zIn[] into a compiled regular
** expression suitable for us by re_match() and return a pointer to the
** compiled regular expression in *ppRe.  Return NULL on success or an
** error message if something goes wrong.
*/
const char *re_compile(ReCompiled **ppRe, const char *zIn, int noCase){
  ReCompiled *pRe;
  const char *zErr;
  int i, j;

  *ppRe = 0;
  pRe = sqlite3_malloc( sizeof(*pRe) );
  if( pRe==0 ){
    return "out of memory";
  }
  memset(pRe, 0, sizeof(*pRe));
  pRe->xNextChar = noCase ? re_next_char_nocase : re_next_char;
  if( re_resize(pRe, 30) ){
    re_free(pRe);
    return "out of memory";
  }
  if( zIn[0]=='^' ){
    zIn++;
  }else{
    re_append(pRe, RE_OP_ANYSTAR, 0);
  }
  pRe->sIn.z = (unsigned char*)zIn;
  pRe->sIn.i = 0;
  pRe->sIn.mx = (int)strlen(zIn);
  zErr = re_subcompile_re(pRe);
  if( zErr ){
    re_free(pRe);
    return zErr;
  }
  if( rePeek(pRe)=='$' && pRe->sIn.i+1>=pRe->sIn.mx ){
    re_append(pRe, RE_OP_MATCH, RE_EOF);
    re_append(pRe, RE_OP_ACCEPT, 0);
    *ppRe = pRe;
  }else if( pRe->sIn.i>=pRe->sIn.mx ){
    re_append(pRe, RE_OP_ACCEPT, 0);
    *ppRe = pRe;
  }else{
    re_free(pRe);
    return "unrecognized character";
  }

  /* The following is a performance optimization.  If the regex begins with
  ** ".*" (if the input regex lacks an initial "^") and afterwards there are
  ** one or more matching characters, enter those matching characters into
  ** zInit[].  The re_match() routine can then search ahead in the input
  ** string looking for the initial match without having to run the whole
  ** regex engine over the string.  Do not worry able trying to match
  ** unicode characters beyond plane 0 - those are very rare and this is
  ** just an optimization. */
  if( pRe->aOp[0]==RE_OP_ANYSTAR ){
    for(j=0, i=1; j<sizeof(pRe->zInit)-2 && pRe->aOp[i]==RE_OP_MATCH; i++){
      unsigned x = pRe->aArg[i];
      if( x<=127 ){
        pRe->zInit[j++] = (unsigned char)x;
      }else if( x<=0xfff ){
        pRe->zInit[j++] = (unsigned char)(0xc0 | (x>>6));
        pRe->zInit[j++] = 0x80 | (x&0x3f);
      }else if( x<=0xffff ){
        pRe->zInit[j++] = (unsigned char)(0xd0 | (x>>12));
        pRe->zInit[j++] = 0x80 | ((x>>6)&0x3f);
        pRe->zInit[j++] = 0x80 | (x&0x3f);
      }else{
        break;
      }
    }
    if( j>0 && pRe->zInit[j-1]==0 ) j--;
    pRe->nInit = j;
  }
  return pRe->zErr;
}

/*
 ** Implementation of the regexp() SQL function.  This function implements
 ** the build-in REGEXP operator.  The first argument to the function is the
 ** pattern and the second argument is the string.  So, the SQL statements:
 **
 **       A REGEXP B
 **
 ** is implemented as regexp(B,A).
 */
static void re_sql_func(
    sqlite3_context *context,
    int argc,
    sqlite3_value **argv
){
  ReCompiled *pRe;          /* Compiled regular expression */
const char *zPattern;     /* The regular expression */
const unsigned char *zStr;/* String being searched */
const char *zErr;         /* Compile error message */
int setAux = 0;           /* True to invoke sqlite3_set_auxdata() */

pRe = sqlite3_get_auxdata(context, 0);
if( pRe==0 ){
  zPattern = (const char*)sqlite3_value_text(argv[0]);
  if( zPattern==0 ) return;
  zErr = re_compile(&pRe, zPattern, 0);
  if( zErr ){
    re_free(pRe);
    sqlite3_result_error(context, zErr, -1);
    return;
  }
  if( pRe==0 ){
    sqlite3_result_error_nomem(context);
    return;
  }
  setAux = 1;
}
zStr = (const unsigned char*)sqlite3_value_text(argv[1]);
if( zStr!=0 ){
  sqlite3_result_int(context, re_match(pRe, zStr, -1));
}
if( setAux ){
  sqlite3_set_auxdata(context, 0, pRe, (void(*)(void*))re_free);
}
}



/*
** This function registered all of the above C functions as SQL
** functions.  This should be the only routine in this file with
** external linkage.
*/
int RegisterExtensionFunctions(sqlite3 *db){
  static const struct FuncDef {
     char *zName;
     signed char nArg;
     u8 argType;           /* 0: none.  1: db  2: (-1) */
     u8 eTextRep;          /* 1: UTF-16.  0: UTF-8 */
     u8 needCollSeq;
     void (*xFunc)(sqlite3_context*,int,sqlite3_value **);
  } aFuncs[] = {
    /* math.h */
    { "acos",               1, 0, SQLITE_UTF8,    0, acosFunc  },
    { "asin",               1, 0, SQLITE_UTF8,    0, asinFunc  },
    { "atan",               1, 0, SQLITE_UTF8,    0, atanFunc  },
    { "atn2",               2, 0, SQLITE_UTF8,    0, atn2Func  },
    /* XXX alias */
    { "atan2",              2, 0, SQLITE_UTF8,    0, atn2Func  },
    { "acosh",              1, 0, SQLITE_UTF8,    0, acoshFunc  },
    { "asinh",              1, 0, SQLITE_UTF8,    0, asinhFunc  },
    { "atanh",              1, 0, SQLITE_UTF8,    0, atanhFunc  },

    { "difference",         2, 0, SQLITE_UTF8,    0, differenceFunc},
    { "degrees",            1, 0, SQLITE_UTF8,    0, rad2degFunc  },
    { "radians",            1, 0, SQLITE_UTF8,    0, deg2radFunc  },

    { "cos",                1, 0, SQLITE_UTF8,    0, cosFunc  },
    { "sin",                1, 0, SQLITE_UTF8,    0, sinFunc },
    { "tan",                1, 0, SQLITE_UTF8,    0, tanFunc },
    { "cot",                1, 0, SQLITE_UTF8,    0, cotFunc },
    { "cosh",               1, 0, SQLITE_UTF8,    0, coshFunc  },
    { "sinh",               1, 0, SQLITE_UTF8,    0, sinhFunc },
    { "tanh",               1, 0, SQLITE_UTF8,    0, tanhFunc },
    { "coth",               1, 0, SQLITE_UTF8,    0, cothFunc },

    { "exp",                1, 0, SQLITE_UTF8,    0, expFunc  },
    { "log",                1, 0, SQLITE_UTF8,    0, logFunc  },
    { "log10",              1, 0, SQLITE_UTF8,    0, log10Func  },
    { "power",              2, 0, SQLITE_UTF8,    0, powerFunc  },
    { "sign",               1, 0, SQLITE_UTF8,    0, signFunc },
    { "sqrt",               1, 0, SQLITE_UTF8,    0, sqrtFunc },
    { "square",             1, 0, SQLITE_UTF8,    0, squareFunc },

    { "ceil",               1, 0, SQLITE_UTF8,    0, ceilFunc },
    { "floor",              1, 0, SQLITE_UTF8,    0, floorFunc },

    { "pi",                 0, 0, SQLITE_UTF8,    1, piFunc },


    /* string */
    { "replicate",          2, 0, SQLITE_UTF8,    0, replicateFunc },
    { "charindex",          2, 0, SQLITE_UTF8,    0, charindexFunc },
    { "charindex",          3, 0, SQLITE_UTF8,    0, charindexFunc },
    { "leftstr",            2, 0, SQLITE_UTF8,    0, leftFunc },
    { "rightstr",           2, 0, SQLITE_UTF8,    0, rightFunc },
#ifndef HAVE_TRIM
    { "ltrim",              1, 0, SQLITE_UTF8,    0, ltrimFunc },
    { "rtrim",              1, 0, SQLITE_UTF8,    0, rtrimFunc },
    { "trim",               1, 0, SQLITE_UTF8,    0, trimFunc },
    { "replace",            3, 0, SQLITE_UTF8,    0, replaceFunc },
#endif
    { "reverse",            1, 0, SQLITE_UTF8,    0, reverseFunc },
    { "proper",             1, 0, SQLITE_UTF8,    0, properFunc },
    { "padl",               2, 0, SQLITE_UTF8,    0, padlFunc },
    { "padr",               2, 0, SQLITE_UTF8,    0, padrFunc },
    { "padc",               2, 0, SQLITE_UTF8,    0, padcFunc },
    { "strfilter",          2, 0, SQLITE_UTF8,    0, strfilterFunc },
    {"regexp",              2, 0, SQLITE_UTF8,    0, re_sql_func },

  };
  /* Aggregate functions */
  static const struct FuncDefAgg {
    char *zName;
    signed char nArg;
    u8 argType;
    u8 needCollSeq;
    void (*xStep)(sqlite3_context*,int,sqlite3_value**);
    void (*xFinalize)(sqlite3_context*);
  } aAggs[] = {
    { "stdev",            1, 0, 0, varianceStep, stdevFinalize  },
    { "variance",         1, 0, 0, varianceStep, varianceFinalize  },
    { "mode",             1, 0, 0, modeStep,     modeFinalize  },
    { "median",           1, 0, 0, modeStep,     medianFinalize  },
    { "lower_quartile",   1, 0, 0, modeStep,     lower_quartileFinalize  },
    { "upper_quartile",   1, 0, 0, modeStep,     upper_quartileFinalize  },
  };
  int i;

  for(i=0; i<sizeof(aFuncs)/sizeof(aFuncs[0]); i++){
    void *pArg = 0;
    switch( aFuncs[i].argType ){
      case 1: pArg = db; break;
      case 2: pArg = (void *)(-1); break;
    }
    //sqlite3CreateFunc
    /* LMH no error checking */
    sqlite3_create_function(db, aFuncs[i].zName, aFuncs[i].nArg,
        aFuncs[i].eTextRep, pArg, aFuncs[i].xFunc, 0, 0);
#if 0
    if( aFuncs[i].needCollSeq ){
      struct FuncDef *pFunc = sqlite3FindFunction(db, aFuncs[i].zName,
          strlen(aFuncs[i].zName), aFuncs[i].nArg, aFuncs[i].eTextRep, 0);
      if( pFunc && aFuncs[i].needCollSeq ){
        pFunc->needCollSeq = 1;
      }
    }
#endif
  }

  for(i=0; i<sizeof(aAggs)/sizeof(aAggs[0]); i++){
    void *pArg = 0;
    switch( aAggs[i].argType ){
      case 1: pArg = db; break;
      case 2: pArg = (void *)(-1); break;
    }
    //sqlite3CreateFunc
    /* LMH no error checking */
    sqlite3_create_function(db, aAggs[i].zName, aAggs[i].nArg, SQLITE_UTF8,
        pArg, 0, aAggs[i].xStep, aAggs[i].xFinalize);
#if 0
    if( aAggs[i].needCollSeq ){
      struct FuncDefAgg *pFunc = sqlite3FindFunction( db, aAggs[i].zName,
          strlen(aAggs[i].zName), aAggs[i].nArg, SQLITE_UTF8, 0);
      if( pFunc && aAggs[i].needCollSeq ){
        pFunc->needCollSeq = 1;
      }
    }
#endif
  }
  return 0;
}

#ifdef COMPILE_SQLITE_EXTENSIONS_AS_LOADABLE_MODULE
int sqlite3_extension_init(
    sqlite3 *db, char **pzErrMsg, const sqlite3_api_routines *pApi){
  SQLITE_EXTENSION_INIT2(pApi);
  RegisterExtensionFunctions(db);
  return 0;
}
#endif /* COMPILE_SQLITE_EXTENSIONS_AS_LOADABLE_MODULE */

map map_make(cmp_func cmp){
  map r;
  r.cmp=cmp;
  r.base = 0;

  return r;
}

void* xcalloc(size_t nmemb, size_t size, char* s){
  void* ret = calloc(nmemb, size);
  return ret;
}

void xfree(void* p){
  free(p);
}

void node_insert(node** n, cmp_func cmp, void *e){
  int c;
  node* nn;
  if(*n==0){
    nn = (node*)xcalloc(1,sizeof(node), "for node");
    nn->data = e;
    nn->count = 1;
    *n=nn;
  }else{
    c=cmp((*n)->data,e);
    if(0==c){
      ++((*n)->count);
      xfree(e);
    }else if(c>0){
      /* put it right here */
      node_insert(&((*n)->l), cmp, e);
    }else{
      node_insert(&((*n)->r), cmp, e);
    }
  }
}

void map_insert(map *m, void *e){
  node_insert(&(m->base), m->cmp, e);
}

void node_iterate(node *n, map_iterator iter, void* p){
  if(n){
    if(n->l)
      node_iterate(n->l, iter, p);
    iter(n->data, n->count, p);
    if(n->r)
      node_iterate(n->r, iter, p);
  }
}

void map_iterate(map *m, map_iterator iter, void* p){
  node_iterate(m->base, iter, p);
}

void node_destroy(node *n){
  if(0!=n){
    xfree(n->data);
    if(n->l)
      node_destroy(n->l);
    if(n->r)
      node_destroy(n->r);

    xfree(n);
  }
}

void map_destroy(map *m){
  node_destroy(m->base);
}

int int_cmp(const void *a, const void *b){
  int64_t aa = *(int64_t *)(a);
  int64_t bb = *(int64_t *)(b);
  /* printf("cmp %d <=> %d\n",aa,bb); */
  if(aa==bb)
    return 0;
  else if(aa<bb)
    return -1;
  else
    return 1;
}

int double_cmp(const void *a, const void *b){
  double aa = *(double *)(a);
  double bb = *(double *)(b);
  /* printf("cmp %d <=> %d\n",aa,bb); */
  if(aa==bb)
    return 0;
  else if(aa<bb)
    return -1;
  else
    return 1;
}
