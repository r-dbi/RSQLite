#define SQLITE_CORE
#define sqlite3_extension_init sqlite3_math_init
#include <R_ext/Visibility.h>
// File obtained from https://www.sqlite.org/contrib and tweaked
// Not integrated into upgrade.R yet because upstream hasn't changed for a long
// time
#include "vendor/extensions/extension-functions.c"
