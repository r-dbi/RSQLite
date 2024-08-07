#define SQLITE_CORE
#include <R_ext/Visibility.h>
#define sqlite3_uuid_init attribute_visible sqlite3_uuid_init

#include "vendor/extensions/uuid.c"
