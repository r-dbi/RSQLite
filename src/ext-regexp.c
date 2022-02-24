#define SQLITE_CORE
#include <R_ext/Visibility.h>
#define sqlite3_regexp_init attribute_visible sqlite3_regexp_init

#include "vendor/extensions/regexp.c"
