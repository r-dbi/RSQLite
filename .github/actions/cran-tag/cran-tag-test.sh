#!/bin/bash
# Check .github/actions/cran-tag/cran-tag.sh offline, against a local bare repository as origin and a `gh` stub: nothing reaches GitHub.
# Process: the header of .github/workflows/cran-submission.yaml
#
#   1. Without a tag or a release, a run creates the draft, with the NEWS.md section as notes and the marker,
#      and pushes an annotated tag at the commit, with the section as its message.
#   2. An existing draft is updated by its id, not duplicated, after its tarball from an earlier attempt
#      is deleted by the asset's id; a failed deletion writes nothing else.
#      Several drafts for the tag stop the run before anything is written, also on a dry run.
#   3. An existing tag stops a real run before anything is written, and stays where it was;
#      a dry run reports it and carries on; --retag moves it, and a dry run with --retag only says so.
#      An origin that cannot be read stops the run before anything is written, also with --retag:
#      only `git ls-remote --exit-code` exiting with 2 means that there is no tag.
#   4. A published release of the tag stops the run before anything is written.
#   5. A dry run writes nothing, and reports the release and the tag a real run would write.
#   6. A version without a NEWS.md section stops the run before anything is written.
#   7. A line starting with `# ` inside a fenced code block does not end the section.
#
# The `gh` stub answers `gh api [-X <method>] <path> --jq <program>` by running the program with jq
# over a JSON file named after the method and the path, and records every call;
# a write also records its method and path, and its fields, and keeps the notes it sends as the body.
#
# Usage:
#   .github/actions/cran-tag/cran-tag-test.sh
#
# Environment variables:
#   KEEP - if non-empty, do not delete the scratch directory

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SCRATCH=$(mktemp -d)
trap '[ -n "${KEEP:-}" ] || rm -rf "$SCRATCH"' EXIT
[ -z "${KEEP:-}" ] || echo "scratch: $SCRATCH"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok   $1"; }
no() { fail=$((fail + 1)); echo "  FAIL $1"; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "         actual: $2"; echo "       expected: $3"; fi; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3"; echo "        in: $2" ;; esac; }
hasnt() { case "$2" in *"$3"*) no "$1"; echo "       present: $3" ;; *) ok "$1" ;; esac; }

command -v jq >/dev/null || {
  echo "jq is needed to answer for the gh stub" >&2
  exit 1
}

# --- the repositories ----------------------------------------------------------
#
# A package with a NEWS.md section for its version, committed and pushed to a bare repository, its origin.
# Git reads no configuration but this one: no signing, and a fixed identity.

cat >"$SCRATCH/gitconfig" <<'EOF'
[user]
	name = Release Test
	email = release-test@example.com
[init]
	defaultBranch = main
EOF
export GIT_CONFIG_GLOBAL=$SCRATCH/gitconfig GIT_CONFIG_NOSYSTEM=1

REMOTE=$SCRATCH/remote.git
PKG=$SCRATCH/pkg
git init --quiet --bare "$REMOTE"
git init --quiet "$PKG"
cat >"$PKG/DESCRIPTION" <<'EOF'
Package: RSQLite
Version: 2.0.0
EOF
# The NEWS.md of the release, with one more line at the end of its section.
news() { # <line>
  cat <<EOF
# RSQLite 2.0.0

## Breaking changes

- Upgrade bundled SQLite.

## Features

- Something new.
$1


# RSQLite 1.9.0

- Old.
EOF
}
news "" >"$PKG/NEWS.md"
git -C "$PKG" add -A
git -C "$PKG" commit --quiet -m "Release 2.0.0"
git -C "$PKG" remote add origin "$REMOTE"
git -C "$PKG" push --quiet origin main
FIRST=$(git -C "$PKG" rev-parse HEAD)
news "- Fix the release notes." >"$PKG/NEWS.md"
git -C "$PKG" commit --quiet -am "Fix the release notes"
git -C "$PKG" push --quiet origin main
HEAD=$(git -C "$PKG" rev-parse HEAD)

# The commit v2.0.0 points to on origin, empty without that tag.
remote_tag() { git -C "$REMOTE" rev-parse --verify --quiet "refs/tags/v2.0.0^{commit}" || true; }
remote_tag_message() { git -C "$REMOTE" tag -l --format='%(contents)' v2.0.0; }
# Puts v2.0.0 on origin at <commit>, as an earlier submission did; the checkout has no tags, as in CI.
tag_on_origin() { # <commit>
  git -C "$PKG" tag -a -f v2.0.0 -m "RSQLite 2.0.0, earlier" "$1"
  git -C "$PKG" push --quiet --force origin refs/tags/v2.0.0
  git -C "$PKG" tag -d v2.0.0 >/dev/null
}
no_tag() {
  git -C "$REMOTE" tag -d v2.0.0 >/dev/null 2>&1 || true
  git -C "$PKG" tag -d v2.0.0 >/dev/null 2>&1 || true
}

# --- the gh stub -------------------------------------------------------------

API=$SCRATCH/api
mkdir -p "$API" "$SCRATCH/bin"
cat >"$SCRATCH/bin/gh" <<'EOF'
#!/bin/bash
echo "gh $*" >>"$SCRATCH/gh.log"
[ "$1" = api ] || { echo "unexpected: gh $*" >&2; exit 1; }
shift
path='' jq='' method=GET
while [ $# -gt 0 ]; do
  case "$1" in
    --jq) jq=$2; shift 2 ;;
    --paginate) shift ;;
    -X) method=$2; shift 2 ;;
    -f | -F)
      echo "$1 $2" >>"$SCRATCH/fields"
      case "$2" in body=@*) cp "${2#body=@}" "$SCRATCH/notes" ;; esac
      shift 2
      ;;
    -*) echo "unexpected: gh api ... $1" >&2; exit 1 ;;
    *) path=$1; shift ;;
  esac
done
if [ "$method" = GET ]; then
  file=$API/$(printf '%s' "$path" | tr '/?=&' '____').json
else
  echo "$method $path" >>"$SCRATCH/writes"
  file=$API/$method-$(printf '%s' "$path" | tr '/?=&' '____').json
fi
if [ ! -f "$file" ]; then
  echo "gh: Not Found (HTTP 404)" >&2
  exit 1
fi
if [ -n "$jq" ]; then jq -r "$jq" "$file"; else cat "$file"; fi
EOF
chmod +x "$SCRATCH/bin/gh"
export SCRATCH API

releases() { # JSON for repos/r-dbi/RSQLite/releases?per_page=100
  cat >"$API/repos_r-dbi_RSQLite_releases_per_page_100.json"
}
DRAFT=https://github.example/r-dbi/RSQLite/releases/tag/untagged-draft
NEW=https://github.example/r-dbi/RSQLite/releases/tag/untagged-new
with_draft() {
  releases <<EOF
[
  {"id": 7, "draft": true, "tag_name": "v2.0.0", "html_url": "$DRAFT", "body": "old notes",
   "assets": [{"id": 32, "name": "notes.txt"}, {"id": 31, "name": "RSQLite_2.0.0.tar.gz"}]},
  {"id": 5, "draft": false, "tag_name": "v1.9.0", "html_url": "https://github.example/v1.9.0", "body": ""}
]
EOF
}
without_draft() {
  releases <<'EOF'
[{"id": 5, "draft": false, "tag_name": "v1.9.0", "html_url": "https://github.example/v1.9.0", "body": ""}]
EOF
}
# What GitHub answers to creating a draft, and to updating the draft 7.
echo "{\"id\": 77, \"html_url\": \"$NEW\"}" >"$API/POST-repos_r-dbi_RSQLite_releases.json"
echo "{\"id\": 7, \"html_url\": \"$DRAFT\"}" >"$API/PATCH-repos_r-dbi_RSQLite_releases_7.json"
# Deleting the asset 31 answers nothing; without this file, the stub fails as for a 404.
deletable() { : >"$API/DELETE-repos_r-dbi_RSQLite_releases_assets_31.json"; }
deletable

NOTES="## Breaking changes

- Upgrade bundled SQLite.

## Features

- Something new.
- Fix the release notes.

<!-- cran-submission: RSQLite 2.0.0 -->"
MESSAGE="RSQLite 2.0.0

## Breaking changes

- Upgrade bundled SQLite.

## Features

- Something new.
- Fix the release notes."

SUMMARY=$SCRATCH/summary.md
# Runs the script as the workflow does, on the package's checkout; prints its output and its exit status.
run() {
  local rc=0 out
  : >"$SUMMARY"
  : >"$SCRATCH/gh.log"
  : >"$SCRATCH/writes"
  : >"$SCRATCH/fields"
  : >"$SCRATCH/output"
  rm -f "$SCRATCH/notes"
  out=$(GITHUB_ACTIONS=true GITHUB_STEP_SUMMARY=$SUMMARY GITHUB_OUTPUT=$SCRATCH/output GH=$SCRATCH/bin/gh GH_REPO=r-dbi/RSQLite \
    GITHUB_REPOSITORY=r-dbi/RSQLite GITHUB_SERVER_URL=https://github.example GITHUB_REF_NAME=release-2.0.0 \
    "$HERE/cran-tag.sh" "$@" "$PKG" 2>&1) || rc=$?
  printf '%s\nexit %s\n' "$out" "$rc"
}

# --- 1: a first run ------------------------------------------------------------

echo
echo "== a first run drafts the release and pushes the tag"
no_tag
without_draft
out=$(run)
has "it succeeds" "$out" "exit 0"
is "it creates one draft" "$(cat "$SCRATCH/writes")" "POST repos/r-dbi/RSQLite/releases"
is "for the tag, targeting the commit, titled after the version" "$(grep -v '^-F body=' "$SCRATCH/fields")" "-f tag_name=v2.0.0
-f target_commitish=$HEAD
-f name=RSQLite 2.0.0
-F draft=true"
is "with the section as notes, and the marker" "$(cat "$SCRATCH/notes")" "$NOTES"
is "the tag is on origin, at the commit" "$(remote_tag)" "$HEAD"
is "annotated with the section" "$(remote_tag_message)" "$MESSAGE"
is "the outputs name the tag, the draft and the tagged commit" "$(cat "$SCRATCH/output")" "tag=v2.0.0
release-id=77
release-url=$NEW
tagged=$HEAD"
summary=$(cat "$SUMMARY")
has "the report links the draft" "$summary" "Created the draft release [RSQLite 2.0.0]($NEW), for the tag \`v2.0.0\` at \`$HEAD\`."
has "and names the tag" "$summary" "Tagged \`$HEAD\` as \`v2.0.0\`."

# --- 2: an existing draft --------------------------------------------------------

echo
echo "== an existing draft is updated"
no_tag
with_draft
out=$(run)
has "it succeeds" "$out" "exit 0"
is "it deletes the earlier tarball by its asset id, then edits the draft by its id, and creates none" "$(cat "$SCRATCH/writes")" "DELETE repos/r-dbi/RSQLite/releases/assets/31
PATCH repos/r-dbi/RSQLite/releases/7"
has "the report says so" "$(cat "$SUMMARY")" "Deleted the draft's \`RSQLite_2.0.0.tar.gz\` first, the tarball of an earlier attempt"
has "retargeting it at the commit" "$(cat "$SCRATCH/fields")" "-f target_commitish=$HEAD"
is "with the notes of this commit" "$(cat "$SCRATCH/notes")" "$NOTES"
is "the tag is on origin, at the commit" "$(remote_tag)" "$HEAD"
has "the outputs name the draft" "$(cat "$SCRATCH/output")" "release-id=7
release-url=$DRAFT"

echo
echo "== a failed deletion of the earlier tarball writes nothing else"
no_tag
rm "$API/DELETE-repos_r-dbi_RSQLite_releases_assets_31.json"
out=$(run)
deletable
has "it fails" "$out" "exit 1"
has "naming the asset" "$out" "::error title=Deleting the earlier tarball failed::The draft $DRAFT carries RSQLite_2.0.0.tar.gz from an earlier attempt"
is "the draft is not edited" "$(cat "$SCRATCH/writes")" "DELETE repos/r-dbi/RSQLite/releases/assets/31"
is "and nothing is tagged" "$(remote_tag)" ""

echo
echo "== a dry run with a draft deletes nothing"
out=$(run --dry-run)
has "it succeeds" "$out" "exit 0"
is "nothing is written to GitHub" "$(cat "$SCRATCH/writes")" ""
has "and says a real run deletes the earlier tarball" "$(cat "$SUMMARY")" "A real run first deletes the draft's \`RSQLite_2.0.0.tar.gz\`, the tarball of an earlier attempt."

echo
echo "== several drafts for the tag stop the run"
no_tag
releases <<EOF
[
  {"id": 9, "draft": true, "tag_name": "v2.0.0", "html_url": "$DRAFT-2", "body": "<!-- cran-submission: RSQLite 2.0.0 -->"},
  {"id": 7, "draft": true, "tag_name": "v2.0.0", "html_url": "$DRAFT", "body": "<!-- cran-submission: RSQLite 2.0.0 -->"}
]
EOF
out=$(run)
has "it fails" "$out" "exit 1"
has "naming both drafts" "$out" "::error title=Several drafts for v2.0.0::These draft releases all carry the tag name v2.0.0: $DRAFT-2 $DRAFT and"
is "nothing is written to GitHub" "$(cat "$SCRATCH/writes")" ""
is "and nothing is tagged" "$(remote_tag)" ""
out=$(run --dry-run)
has "a dry run fails too" "$out" "exit 1"

# --- 3: an existing tag ----------------------------------------------------------

echo
echo "== an existing tag stops a real run"
no_tag
tag_on_origin "$FIRST"
with_draft
out=$(run)
has "it fails" "$out" "exit 1"
has "naming the tag and its commit" "$out" "::error title=Tag v2.0.0 exists::The tag v2.0.0 exists and points to $FIRST"
is "nothing is written to GitHub" "$(cat "$SCRATCH/writes")" ""
is "the tag stays where it was" "$(remote_tag)" "$FIRST"
summary=$(cat "$SUMMARY")
has "the report says how to proceed" "$summary" "#### How to resolve"
has "with retag only for a submission CRAN never received" "$summary" "gh workflow run cran-submission.yaml --repo r-dbi/RSQLite --ref release-2.0.0 -f retag=true"

echo
echo "== a dry run reports an existing tag and carries on"
out=$(run --dry-run)
has "it succeeds" "$out" "exit 0"
has "with the error annotated" "$out" "::error title=Tag v2.0.0 exists::"
is "nothing is written to GitHub" "$(cat "$SCRATCH/writes")" ""
is "the tag stays where it was" "$(remote_tag)" "$FIRST"
has "the report says a real run stops" "$(cat "$SUMMARY")" "Dry run: a real run stops before drafting or tagging, because \`v2.0.0\` exists at \`$FIRST\`."

echo
echo "== a dry run with retag says it would move the tag"
out=$(run --dry-run --retag)
has "it succeeds" "$out" "exit 0"
has "saying so" "$out" "::notice title=Dry run::A real run would move the existing tag v2.0.0 from $FIRST to $HEAD"
is "nothing is written to GitHub" "$(cat "$SCRATCH/writes")" ""
is "the tag stays where it was" "$(remote_tag)" "$FIRST"

echo
echo "== retag moves the tag"
out=$(run --retag)
has "it succeeds" "$out" "exit 0"
has "with a warning" "$out" "::warning title=Moving the tag v2.0.0::Moving the existing tag v2.0.0 from $FIRST to $HEAD"
is "it deletes the earlier attempt's tarball and updates the draft" "$(cat "$SCRATCH/writes")" "DELETE repos/r-dbi/RSQLite/releases/assets/31
PATCH repos/r-dbi/RSQLite/releases/7"
is "the tag moves to the commit" "$(remote_tag)" "$HEAD"
is "with the section as its message" "$(remote_tag_message)" "$MESSAGE"

echo
echo "== an origin that cannot be read stops the run before anything is written"
no_tag
with_draft
git -C "$PKG" remote set-url origin "$SCRATCH/unreachable.git"
out=$(run)
has "it fails" "$out" "exit 1"
has "saying the tag cannot be checked" "$out" "::error title=The tag v2.0.0 cannot be checked::\`git ls-remote origin refs/tags/v2.0.0\` exited with status 128"
has "and that nothing was written" "$out" "Nothing was drafted, tagged or uploaded."
is "the existing draft is neither listed nor touched" "$(cat "$SCRATCH/gh.log")" ""
out=$(run --retag)
has "with retag too" "$out" "exit 1"
is "which touches nothing either" "$(cat "$SCRATCH/gh.log")" ""
git -C "$PKG" remote set-url origin "$REMOTE"
is "and nothing is tagged" "$(remote_tag)" ""

# --- 4: a published release --------------------------------------------------------

echo
echo "== a published release stops the run"
no_tag
releases <<'EOF'
[{"id": 8, "draft": false, "tag_name": "v2.0.0", "html_url": "https://github.example/v2.0.0", "body": ""}]
EOF
out=$(run)
has "it fails" "$out" "exit 1"
has "naming the release" "$out" "::error title=Release v2.0.0 is already published::The release v2.0.0 is published at https://github.example/v2.0.0"
is "nothing is written to GitHub" "$(cat "$SCRATCH/writes")" ""
is "and nothing is tagged" "$(remote_tag)" ""

# --- 5: a dry run --------------------------------------------------------------------

echo
echo "== a dry run writes nothing"
no_tag
without_draft
out=$(run --dry-run)
has "it succeeds" "$out" "exit 0"
is "nothing is written to GitHub" "$(cat "$SCRATCH/writes")" ""
is "and nothing is tagged" "$(remote_tag)" ""
is "the output names the tag only" "$(cat "$SCRATCH/output")" "tag=v2.0.0"
summary=$(cat "$SUMMARY")
has "the report says what a real run does" "$summary" "Dry run: a real run would create a draft release:"
has "with the notes" "$summary" "$NOTES"
has "and the tag's message" "$summary" "Dry run: a real run tags \`$HEAD\` as \`v2.0.0\`, with this message:"

# --- 6: no NEWS.md section -------------------------------------------------------------

echo
echo "== a version without a NEWS.md section stops the run"
sed -i.bak 's/^Version: 2.0.0$/Version: 2.0.1/' "$PKG/DESCRIPTION"
out=$(run)
mv "$PKG/DESCRIPTION.bak" "$PKG/DESCRIPTION"
has "it fails" "$out" "exit 1"
has "naming the heading it looked for" "$out" "NEWS.md has no section headed \`# RSQLite 2.0.1\`"
is "without asking GitHub" "$(cat "$SCRATCH/gh.log")" ""
is "and nothing is tagged" "$(git -C "$REMOTE" tag -l)" ""

# --- 7: a code block in the section ------------------------------------------------------

echo
echo "== a code block with a comment line does not end the section"
cp "$PKG/NEWS.md" "$SCRATCH/NEWS.md.orig"
cat >"$PKG/NEWS.md" <<'EOF'
# RSQLite 2.0.0

- Connect like this:

```r
# connect
con <- dbConnect(RSQLite::SQLite())
```

- After the backticks.

~~~~
# a shell comment
```
# still in the block
~~~~

- After the tildes.

# RSQLite 1.9.0

- Old.
EOF
out=$(run --dry-run)
mv "$SCRATCH/NEWS.md.orig" "$PKG/NEWS.md"
has "it succeeds" "$out" "exit 0"
summary=$(cat "$SUMMARY")
# shellcheck disable=SC2016  # Markdown backticks, no command substitution
has "the notes keep the code block" "$summary" '```r
# connect
con <- dbConnect(RSQLite::SQLite())
```'
has "and the bullet after it" "$summary" "- After the backticks."
has "a shorter fence of the other kind does not close a block" "$summary" "# still in the block"
has "and the section goes on after the block" "$summary" "- After the tildes.

<!-- cran-submission: RSQLite 2.0.0 -->"
hasnt "up to the next heading" "$summary" "RSQLite 1.9.0"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
