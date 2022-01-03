#define SQLITE_CORE
#define sqlite3_extension_init sqlite3_math_init
#include <R_ext/Visibility.h>
#include "vendor/sqlite3/extension-functions.c"
