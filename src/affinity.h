#ifndef __AFFINITY_H__
#define __AFFINITY_H__

#ifdef __cplusplus
extern "C" {
#endif

#define SQLITE_AFF_BLOB     'A'
#define SQLITE_AFF_TEXT     'B'
#define SQLITE_AFF_NUMERIC  'C'
#define SQLITE_AFF_INTEGER  'D'
#define SQLITE_AFF_REAL     'E'

char sqlite3AffinityType(const char* zIn);

#ifdef __cplusplus
} // extern "C" {
#endif

#endif // #ifndef __AFFINITY_H__
