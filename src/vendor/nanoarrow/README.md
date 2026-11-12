# Vendored nanoarrow

`nanoarrow.c`, `nanoarrow.h` and `nanoarrow.hpp` are the bundled sources of the Apache Arrow nanoarrow library, version 0.9.0,
copied from the `src/` directory of the nanoarrow R package's CRAN sources (`nanoarrow_0.9.0.tar.gz`).
`LICENSE.txt` and `NOTICE.txt` are the files of the same name from the nanoarrow release tag `apache-arrow-nanoarrow-0.9.0`.

The single delta is the line `#define NANOARROW_NAMESPACE RSQLite` in `nanoarrow.h` (upstream: `RPkg`),
which prefixes the library's exported symbols so that they cannot collide with the copy inside the nanoarrow package or arrow's.

To update:

1. Download the CRAN sources of the new nanoarrow version and copy `src/nanoarrow.c`, `src/nanoarrow.h` and `src/nanoarrow.hpp` over these files.
2. Set the namespace line in `nanoarrow.h` back to `#define NANOARROW_NAMESPACE RSQLite`.
3. Copy `LICENSE.txt` and `NOTICE.txt` from the release tag, and update the version above.
4. Rebuild, and check that `nm -D RSQLite.so | grep ' T '` lists no nanoarrow symbol without the `RSQLite` prefix.
