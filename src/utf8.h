#ifndef RSQLITE_UTF8_H
#define RSQLITE_UTF8_H

#include <stddef.h>

// Whether the `size` bytes at `text` are well-formed UTF-8 without a NUL byte,
// which is what an R string can hold.
// Follows the byte ranges of RFC 3629: no overlong forms, no surrogates,
// nothing beyond U+10FFFF.
inline bool rsqlite_is_utf8_string(const char* text, size_t size) {
  const unsigned char* p = reinterpret_cast<const unsigned char*>(text);
  const unsigned char* end = p + size;

  while (p < end) {
    unsigned char c = *p;
    if (c == 0x00) {
      return false;
    }
    if (c < 0x80) {
      ++p;
      continue;
    }

    size_t n;
    unsigned char lo = 0x80;
    unsigned char hi = 0xBF;
    if (c >= 0xC2 && c <= 0xDF) {
      n = 1;
    } else if (c == 0xE0) {
      n = 2;
      lo = 0xA0;
    } else if ((c >= 0xE1 && c <= 0xEC) || c == 0xEE || c == 0xEF) {
      n = 2;
    } else if (c == 0xED) {
      n = 2;
      hi = 0x9F;
    } else if (c == 0xF0) {
      n = 3;
      lo = 0x90;
    } else if (c >= 0xF1 && c <= 0xF3) {
      n = 3;
    } else if (c == 0xF4) {
      n = 3;
      hi = 0x8F;
    } else {
      return false;
    }

    if (static_cast<size_t>(end - p) < n + 1) {
      return false;
    }
    // The first continuation byte has the restricted range
    if (p[1] < lo || p[1] > hi) {
      return false;
    }
    for (size_t k = 2; k <= n; ++k) {
      if (p[k] < 0x80 || p[k] > 0xBF) {
        return false;
      }
    }
    p += n + 1;
  }

  return true;
}

#endif  // RSQLITE_UTF8_H
