// Extracted from sqlite3.c

#include "affinity.h"

#ifndef UINT32_TYPE
# ifdef HAVE_UINT32_T
#  define UINT32_TYPE uint32_t
# else
#  define UINT32_TYPE unsigned int
# endif
#endif

/* An array to map all upper-case characters into their corresponding
 ** lower-case character.
 **
 ** SQLite only considers US-ASCII (or EBCDIC) characters.  We do not
 ** handle case conversions for the UTF character set since the tables
 ** involved are nearly as big or bigger than SQLite itself.
 */
const unsigned char sqlite3UpperToLower[] = {
  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
  18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
  36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53,
  54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 97, 98, 99,100,101,102,103,
  104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,
  122, 91, 92, 93, 94, 95, 96, 97, 98, 99,100,101,102,103,104,105,106,107,
  108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,
  126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,
  144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,
  162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,
  180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,
  198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,
  216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,
  234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,
  252,253,254,255
};

/*
** Scan the column type name zType (length nType) and return the
** associated affinity type.
**
** This routine does a case-independent search of zType for the
** substrings in the following table. If one of the substrings is
** found, the corresponding affinity is returned. If zType contains
** more than one of the substrings, entries toward the top of
** the table take priority. For example, if zType is 'BLOBINT',
** SQLITE_AFF_INTEGER is returned.
**
** Substring     | Affinity
** --------------------------------
** 'INT'         | SQLITE_AFF_INTEGER
** 'CHAR'        | SQLITE_AFF_TEXT
** 'CLOB'        | SQLITE_AFF_TEXT
** 'TEXT'        | SQLITE_AFF_TEXT
** 'BLOB'        | SQLITE_AFF_BLOB
** 'REAL'        | SQLITE_AFF_REAL
** 'FLOA'        | SQLITE_AFF_REAL
** 'DOUB'        | SQLITE_AFF_REAL
**
** If none of the substrings in the above table are found,
** SQLITE_AFF_NUMERIC is returned.
*/
char sqlite3AffinityType(const char *zIn){
  UINT32_TYPE h = 0;
  char aff = SQLITE_AFF_NUMERIC;
  const char *zChar = 0;

  if( zIn==0 ) return aff;
  while( zIn[0] ){
    h = (h<<8) + sqlite3UpperToLower[(*zIn)&0xff];
    zIn++;
    if( h==(('c'<<24)+('h'<<16)+('a'<<8)+'r') ){             /* CHAR */
      aff = SQLITE_AFF_TEXT;
      zChar = zIn;
    }else if( h==(('c'<<24)+('l'<<16)+('o'<<8)+'b') ){       /* CLOB */
      aff = SQLITE_AFF_TEXT;
    }else if( h==(('t'<<24)+('e'<<16)+('x'<<8)+'t') ){       /* TEXT */
      aff = SQLITE_AFF_TEXT;
    }else if( h==(('b'<<24)+('l'<<16)+('o'<<8)+'b')          /* BLOB */
        && (aff==SQLITE_AFF_NUMERIC || aff==SQLITE_AFF_REAL) ){
      aff = SQLITE_AFF_BLOB;
      if( zIn[0]=='(' ) zChar = zIn;
#ifndef SQLITE_OMIT_FLOATING_POINT
    }else if( h==(('r'<<24)+('e'<<16)+('a'<<8)+'l')          /* REAL */
        && aff==SQLITE_AFF_NUMERIC ){
      aff = SQLITE_AFF_REAL;
    }else if( h==(('f'<<24)+('l'<<16)+('o'<<8)+'a')          /* FLOA */
        && aff==SQLITE_AFF_NUMERIC ){
      aff = SQLITE_AFF_REAL;
    }else if( h==(('d'<<24)+('o'<<16)+('u'<<8)+'b')          /* DOUB */
        && aff==SQLITE_AFF_NUMERIC ){
      aff = SQLITE_AFF_REAL;
#endif
    }else if( (h&0x00FFFFFF)==(('i'<<16)+('n'<<8)+'t') ){    /* INT */
      aff = SQLITE_AFF_INTEGER;
      break;
    }
  }

  (void)zChar;

  return aff;
}
