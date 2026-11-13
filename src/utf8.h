#ifndef RSQLITE_UTF8_H
#define RSQLITE_UTF8_H

#include <stddef.h>

// Whether the `size` bytes at `text` are well-formed UTF-8 without a NUL byte,
// which is what an R string can hold.
// Follows the byte ranges of RFC 3629: no overlong forms, no surrogates,
// nothing beyond U+10FFFF.
// `text` may be NULL if `size` is 0.
bool rsqlite_is_utf8_string(const char* text, size_t size);

#endif  // RSQLITE_UTF8_H
