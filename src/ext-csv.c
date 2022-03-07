#define SQLITE_CORE
#include <R_ext/Visibility.h>
#define sqlite3_csv_init attribute_visible sqlite3_csv_init

#include "vendor/extensions/csv.c"
