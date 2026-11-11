#!/usr/bin/env bash
# Driver of the experiment in this directory; README.md says what it measures.
#
# Usage: run.sh [package directory]
# The package directory defaults to the root of this repository.
#
# Builds the package in place, as a developer would, into a temporary library.
# Along the way it edits src/vendor/extensions/http.c and src/ext-http.dd,
# touches src/ext-http.c, and lets the build regenerate src/*.dd files.
# On exit it restores those files with their time stamps,
# and deletes src/ext-http.o and src/ext-http.d,
# so that the next build compiles ext-http.c from the restored sources.
# The full log of each build is written to the temporary directory, which is deleted on exit,
# so a build that fails has the tail of its log printed to stderr first.

set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
cd "${1:-$here/../..}"

vendored=src/vendor/extensions/http.c
work=$(mktemp -d)
lib=$work/lib
mkdir "$lib" "$work/backup"
cp -p "$vendored" "$work/vendored-http.c"
cp -p src/ext-http.c src/*.dd "$work/backup/"

restore() {
  cp -p "$work/vendored-http.c" "$vendored"
  cp -p "$work/backup/"* src/
  rm -f src/ext-http.o src/ext-http.d
  rm -rf "$work"
}
trap restore EXIT

# Reports what a build did, from its log, and the time stamp of ext-http.o.
report() {
  local log=$1
  local compiled n
  if grep -q "R config changed" "$log"; then
    echo "  .Rconfig: changed, so every object listed in a .dd file is out of date"
  fi
  for dd in $(sed -n 's/^making \(.*\)\.d from .*/\1.dd/p' "$log"); do
    echo "  regenerated: $dd"
  done
  compiled=$(sed -n 's/.* -c \([^ ]*\) -o .*/\1/p' "$log")
  n=$(printf '%s' "$compiled" | grep -c . || true)
  if [ "$n" -eq 0 ]; then
    echo "  compiled: nothing"
  elif [ "$n" -gt 3 ]; then
    echo "  compiled: $n files"
  else
    echo "  compiled: $(printf '%s\n' "$compiled" | paste -s -d ' ')"
  fi
  if grep -q -- ' -shared ' "$log"; then
    echo "  linked: RSQLite.so"
  else
    echo "  linked: nothing"
  fi
  grep -h "#pragma message: experiment" "$log" | sed 's/^/  /' || true
  echo "  ext-http.o modified: $(stat -c %y src/ext-http.o)"
}

# Counts the lines of a .dd file, and the absolute and the vendored paths among them.
dd_summary() {
  echo "$(wc -l < "$1") lines, $(grep -c '^ */' "$1" || true) absolute paths, $(grep -c '^ *vendor/' "$1" || true) vendored paths"
}

# Runs a build with its output in $work/<step>.log.
# If the build fails, prints the last 30 lines of the log and the step to stderr, and exits.
build() {
  local step=$1
  shift
  if ! "$@" > "$work/$step.log" 2>&1; then
    echo "Step $step failed: $*" >&2
    tail -n 30 "$work/$step.log" >&2
    exit 1
  fi
  report "$work/$step.log"
}

install() {
  local step=$1
  shift
  build "$step" R CMD INSTALL --no-clean-on-error "$@" -l "$lib" .
}

compile_dll() {
  build "$1" Rscript -e 'pkgbuild::compile_dll(".", quiet = FALSE)'
}

edit_vendored() {
  sleep 1
  echo "#pragma message(\"experiment: $1\")" >> "$vendored"
}

echo "RSQLite $(sed -n 's/^Version: //p' DESCRIPTION), commit $(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "src/ext-http.dd as committed:"
sed 's/^/  /' src/ext-http.dd

echo
echo "1. Full build: R CMD INSTALL --preclean"
install 1 --preclean

echo
echo "2. Edit $vendored, rebuild: R CMD INSTALL"
edit_vendored "edit 1"
install 2

echo
echo "3. Add $vendored to src/ext-http.dd by hand, rebuild: R CMD INSTALL"
sed -i 's|^  ext-http.c \\$|&\n  vendor/extensions/http.c \\|' src/ext-http.dd
sed 's/^/  /' src/ext-http.dd
install 3

echo
echo "4. Touch src/ext-http.c, rebuild: R CMD INSTALL"
sleep 1
touch src/ext-http.c
install 4
echo "  src/ext-http.dd now:"
sed 's/^/    /' src/ext-http.dd

echo
echo "5. Edit $vendored again, rebuild: R CMD INSTALL"
edit_vendored "edit 2"
install 5

echo
echo "6. Build with pkgbuild::compile_dll(), as devtools::load_all() does"
compile_dll 6
echo "  src/cpp11.dd: $(dd_summary src/cpp11.dd); as committed: $(dd_summary "$work/backup/cpp11.dd")"

echo
echo "7. Edit $vendored again, rebuild: pkgbuild::compile_dll()"
edit_vendored "edit 3"
compile_dll 7

echo
echo "8. The rule in src/Makevars.deps, run by make on the -MM output of each compiler for ext-http.c"
for cc in gcc clang; do
  if ! command -v "$cc" > /dev/null; then
    echo "  $cc: not installed"
    continue
  fi
  sleep 1
  (
    cd src
    "$cc" -MM -I"$(R RHOME)/include" -DNDEBUG -Ivendor ext-http.c > ext-http.d
    echo "  $($cc --version | head -n 1), output with the indent of each line:"
    awk '{ match($0, /^ */); printf "    indent %d: %s\n", RLENGTH, substr($0, RLENGTH + 1) }' ext-http.d
    make -s -f Makevars.deps ext-http.dd
    echo "  src/ext-http.dd made from it:"
    sed 's/^/    /' ext-http.dd
  )
done
