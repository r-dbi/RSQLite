#include "pch.h"
#include "utf8.h"

#include <stdint.h>
#include <string.h>

#include <vector>

// The length of the UTF-8 sequence at the start of the `size` bytes at `s`,
// or 0 if it is not well-formed or is a NUL byte.
static size_t utf8_sequence_length(const unsigned char* s, size_t size) {
  const unsigned char c = s[0];
  if (c < 0x80) {
    return (c == 0x00) ? 0 : 1;
  }

  // The range of the first continuation byte is narrower after some lead bytes:
  // this rules out overlong forms, surrogates, and values beyond U+10FFFF
  size_t n;
  unsigned char lo = 0x80;
  unsigned char hi = 0xBF;
  if (c >= 0xC2 && c <= 0xDF) {
    n = 2;
  } else if (c == 0xE0) {
    n = 3;
    lo = 0xA0;
  } else if (c == 0xED) {
    n = 3;
    hi = 0x9F;
  } else if (c >= 0xE1 && c <= 0xEF) {
    n = 3;
  } else if (c == 0xF0) {
    n = 4;
    lo = 0x90;
  } else if (c >= 0xF1 && c <= 0xF3) {
    n = 4;
  } else if (c == 0xF4) {
    n = 4;
    hi = 0x8F;
  } else {
    // A continuation byte, the lead byte of an overlong two-byte form,
    // or a byte that never occurs in UTF-8
    return 0;
  }

  if (size < n) {
    return 0;
  }
  if (s[1] < lo || s[1] > hi) {
    return 0;
  }
  for (size_t k = 2; k < n; ++k) {
    if (s[k] < 0x80 || s[k] > 0xBF) {
      return 0;
    }
  }
  return n;
}

bool rsqlite_is_utf8_string(const char* text, size_t size) {
  const unsigned char* const s = reinterpret_cast<const unsigned char*>(text);
  const uint64_t ones = UINT64_C(0x0101010101010101);
  const uint64_t highs = UINT64_C(0x8080808080808080);

  size_t i = 0;
  while (i < size) {
    // Most text is ASCII: eight bytes at a time, a word whose bytes are all
    // in 1..127 needs no further check
    if (size - i >= 8) {
      uint64_t word;
      memcpy(&word, s + i, 8);
      // A NUL byte borrows in `word - ones`, a byte above 127 has its high bit
      if ((((word - ones) | word) & highs) == 0) {
        i += 8;
        continue;
      }
    }

    // Otherwise check the bytes of that word sequence by sequence,
    // the last sequence may extend beyond the word
    const size_t stop = (size - i >= 8) ? i + 8 : size;
    while (i < stop) {
      const size_t n = utf8_sequence_length(s + i, size - i);
      if (n == 0) {
        return false;
      }
      i += n;
    }
  }

  return true;
}

// For testing: whether each raw vector in `x` holds a valid R string
[[cpp11::register]]
cpp11::logicals utf8_valid(cpp11::list x) {
  const R_xlen_t n = x.size();
  cpp11::writable::logicals out(n);
  for (R_xlen_t k = 0; k < n; ++k) {
    cpp11::raws bytes(x[k]);
    const size_t size = static_cast<size_t>(bytes.size());
    // Continuation bytes behind the input: a read past `size` would turn a
    // truncated sequence into a valid one, so the tests would see it.
    // Empty input is passed as NULL, which the header allows.
    std::vector<char> buf(size + 3, '\x80');
    if (size > 0) {
      memcpy(buf.data(), RAW(bytes), size);
    }
    const bool valid =
      rsqlite_is_utf8_string(size > 0 ? buf.data() : NULL, size);
    out[k] = cpp11::r_bool(valid);
  }
  return out;
}
