#define SQLITE_CORE
#include <R_ext/Visibility.h>
#define sqlite3_series_init attribute_visible sqlite3_series_init

#include "vendor/extensions/series.c"
