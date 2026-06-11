#define SQLITE_CORE
#include <R_ext/Visibility.h>
#define sqlite3_http_init attribute_visible sqlite3_http_init
/* Include our minimal bundled HTTP VFS (or stub) */
#include "vendor/extensions/http.c"
