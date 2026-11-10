#!/usr/bin/env bash
# Draft the GitHub release of a CRAN submission and tag the commit, as the `tag` job of .github/workflows/cran-submission.yaml does.
# Process: the header of .github/workflows/cran-submission.yaml
#
# The package and its version come from DESCRIPTION in <package dir>, the commit is its HEAD,
# and the tag is `v<version>`.
# The NEWS.md section of the version, from the heading `# <package> <version>` to the next level-one heading,
# is the tag's message, without the leading `# `.
# The release is a draft titled `<package> <version>`, with the section without its heading as notes,
# ended by the marker `<!-- cran-submission: <package> <version> -->`,
# by which .github/actions/cran-release/cran-release.sh publishes it once Posit's package manager serves the version.
#
# In this order, so that every check comes before the first write:
#   1. An existing tag `v<version>` on origin stops the run: a tag is never moved, unless with --retag,
#      which moves it to the commit; a dry run reports the existing tag and carries on.
#   2. A published release of the tag stops the run.
#   3. The draft release is created, or the draft that is there is updated.
#   4. The commit is tagged, and the tag is pushed to origin, with --force only for --retag.
# --dry-run writes nothing, and prints and reports the release and the tag a real run would write.
#
# Usage:
#   .github/actions/cran-tag/cran-tag.sh [--dry-run] [--retag] [<package dir>]
#
# <package dir> defaults to the root of this repository; it is a checkout whose `origin` the tag is pushed to,
# with a Git identity for the annotated tag.
# With GITHUB_OUTPUT set, the script writes `tag`, and on a real run `release-url` once the draft is written.
# Exit status: 0 on success, 1 when a check stops the run or a write fails, 2 on a usage error.
#
# Environment:
#   GH_REPO     the repository, owner/name; defaults to GITHUB_REPOSITORY
#   GH          the gh command, default `gh`; .github/actions/cran-tag/cran-tag-test.sh stubs it
#   GITHUB_ACTIONS, GITHUB_STEP_SUMMARY, GITHUB_OUTPUT, GITHUB_SERVER_URL, GITHUB_REPOSITORY, GITHUB_SHA, GITHUB_REF_NAME
#               the log's groups and annotations, the report, the step outputs, the commit links,
#               and the ref in the advice on dispatching again (.github/actions/cran-lib/cran-lib.sh)

set -euo pipefail

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../cran-lib/cran-lib.sh
. "$(dirname "$0")/../cran-lib/cran-lib.sh"

usage() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

dry_run='' retag='' pkgdir=''
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=1 ;;
    --retag) retag=1 ;;
    -*) usage ;;
    *)
      [ -z "$pkgdir" ] || usage
      pkgdir=$1
      ;;
  esac
  shift
done
[ -n "$pkgdir" ] || pkgdir=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$pkgdir"

repo=${GH_REPO:-${GITHUB_REPOSITORY:-}}
[ -n "$repo" ] || {
  echo "Set GH_REPO (or GITHUB_REPOSITORY) to the repository, owner/name." >&2
  exit 2
}
gh=${GH:-gh}
rerun="gh workflow run cran-submission.yaml --repo $repo --ref ${GITHUB_REF_NAME:-<ref>}"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

output() { # <name> <value>
  [ -z "${GITHUB_OUTPUT:-}" ] || printf '%s=%s\n' "$1" "$2" >>"$GITHUB_OUTPUT"
}

commit_of "$pkgdir"
commit=$(git rev-parse HEAD)
summary "## Tag and draft release${dry_run:+: dry run}" ""
[ -z "$commit_md" ] || summary "$commit_md" ""

# --- the version and its NEWS.md section -------------------------------------

group "NEWS: the section of the version"
pkg=$(sed -n 's/^Package: *//p' DESCRIPTION)
version=$(sed -n 's/^Version: *//p' DESCRIPTION)
tag=v$version
title="$pkg $version"
val "commit" "$commit${GITHUB_REF_NAME:+ ($GITHUB_REF_NAME)}"
val "package" "$pkg"
val "version" "$version"
val "tag" "$tag"

message=$work/tag-message.md
: >"$message"
if [ -f NEWS.md ]; then
  # The section from the version's heading to the next one, without the leading "# ".
  awk -v heading="# $title" '
    $0 == heading { found = 1; print substr($0, 3); next }
    found && /^# / { exit }
    found { print }
  ' NEWS.md >"$message"
fi
if [ ! -s "$message" ]; then
  fail "NEWS" "No NEWS.md section" "NEWS.md has no section headed \`# $title\`. Nothing was drafted, tagged or uploaded." -- \
    "Fold the development sections of NEWS.md into one section headed exactly \`# $title\`, without a date, and dispatch again on the commit that carries it."
fi
# The release carries the section without its heading, as the earlier releases do; its title is the heading.
# The marker at the end, which GitHub does not render, is how cran-release.sh finds the drafts to publish.
notes=$work/release-notes.md
{
  # Without the heading, and without blank lines before and after the section.
  tail -n +2 "$message" | sed '/./,$!d' | awk 'NF { for (; blank > 0; blank--) print ""; print; next } { blank++ }'
  echo
  echo "<!-- cran-submission: $title -->"
} >"$notes"
val "NEWS.md section" "$(wc -l <"$message" | tr -d ' ') lines"
endgroup
output tag "$tag"

# --- an existing tag ----------------------------------------------------------

# An existing tag is never moved, unless the run was dispatched with `retag`:
# a version CRAN has received is never submitted again.
group "Tag: is there a $tag on origin?"
moves='' stops=''
if git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null; then
  git fetch --quiet --depth=1 origin "refs/tags/$tag:refs/tags/$tag"
  existing=$(git rev-parse "$tag^{commit}")
  val "existing tag" "$tag at $existing"
  git cat-file -p "$tag"
  if [ -n "$retag" ]; then
    moves=$existing
    endgroup
    if [ -n "$dry_run" ]; then
      notice "Dry run" "A real run would move the existing tag $tag from $moves to $commit, because the run was dispatched with retag."
    else
      warn "Moving the tag $tag" "Moving the existing tag $tag from $moves to $commit, because the run was dispatched with retag."
    fi
    summary "### Tag: \`$tag\` exists, moved with \`retag\`" "" "The tag \`$tag\` points to \`$existing\`; this run moves it to \`$commit\`." ""
  else
    resolve=(
      "If CRAN received $title, a new submission is a new version: bump \`DESCRIPTION\` and \`NEWS.md\` to the next patch version, and dispatch on the commit that carries it."
      "Only if CRAN never received this version, for instance because the upload failed, dispatch again with \`retag\` on: \`$rerun -f retag=true\`."
    )
    if [ -z "$dry_run" ]; then
      fail "Tag" "Tag $tag exists" "The tag $tag exists and points to $existing, and this workflow never moves a tag without retag. Nothing was drafted, tagged or uploaded." -- "${resolve[@]}"
    fi
    failure "Tag" "Tag $tag exists" "The tag $tag exists and points to $existing; a real run stops here without retag. The dry run carries on." -- "${resolve[@]}"
    stops=$existing
  fi
else
  val "existing tag" "none"
fi
endgroup

# --- the draft release --------------------------------------------------------

# Before the tag, so that a published release stops the run before the tag moves.
# A draft has no tag yet, so it is found by its pending tag name in the list of releases.
group "Release: $title"
if ! "$gh" api --paginate "repos/$repo/releases?per_page=100" \
  --jq ".[] | select(.tag_name == \"$tag\") | [(if .draft then \"draft\" else \"published\" end), .html_url] | @tsv" \
  >"$work/found" 2>"$work/gh.err"; then
  cat "$work/gh.err" >&2
  fail "Release" "The releases cannot be listed" "\`gh api repos/$repo/releases\` failed: $(head -n 1 "$work/gh.err")" "$work/gh.err" -- \
    "Check that the token may read the repository's releases; drafts need \`contents: write\`." \
    "Rerun the workflow; nothing was drafted, tagged or uploaded."
fi
published=$(awk -F '\t' '$1 == "published" { print $2; exit }' "$work/found")
draft=$(awk -F '\t' '$1 == "draft" { print $2; exit }' "$work/found")

if [ -n "$published" ]; then
  fail "Release" "Release $tag is already published" "The release $tag is published at $published, and this workflow does not touch a published release. Nothing was tagged or uploaded." -- \
    "If $title is out, a new submission needs a new version: bump \`DESCRIPTION\` and \`NEWS.md\`, and dispatch again." \
    "If the published release is a mistake, open it, and save it as a draft again or delete it; then dispatch again, and this job updates the draft."
fi

if [ -n "$draft" ]; then
  action="update the draft release $draft"
else
  action="create a draft release"
fi
say "Release: $action"
val "tag" "$tag"
val "target" "$commit"
val "title" "$title"
val "draft" "true"
say "Release notes:"
cat "$notes"

if [ -n "$dry_run" ]; then
  endgroup
  notice "Dry run" "Would $action titled '$title' for $tag at $commit; nothing was created."
  summary "### Release" "" "Dry run: a real run would $action:" "" \
    "- Tag: \`$tag\`, target \`$commit\`" \
    "- Title: $title" \
    "- Draft: yes, published by the nightly \`cran-release.yaml\` once Posit's package manager serves the version" "" \
    "<details><summary>Release notes</summary>" "" '````markdown' "$(cat "$notes")" '````' "" "</details>" ""
else
  write_failed() {
    cat "$work/gh.err" >&2
    fail "Release" "Writing the draft release failed" "Trying to $action, \`gh release\` failed: $(head -n 1 "$work/gh.err"). Nothing was tagged or uploaded." "$work/gh.err" -- \
      "Check that the token may write releases: the job needs \`contents: write\`." \
      "Then dispatch again; the run updates the draft if one was written."
  }
  if [ -n "$draft" ]; then
    "$gh" release edit "$tag" --repo "$repo" --draft --target "$commit" --title "$title" --notes-file "$notes" >/dev/null 2>"$work/gh.err" || write_failed
    url=$draft
    done_="Updated the draft release"
  else
    url=$("$gh" release create "$tag" --repo "$repo" --draft --target "$commit" --title "$title" --notes-file "$notes" 2>"$work/gh.err") || write_failed
    done_="Created the draft release"
  fi
  output release-url "$url"
  endgroup
  notice "Draft release" "$done_ $title at $url; the nightly cran-release.yaml publishes it once Posit's package manager serves the version."
  summary "### Release" "" "$done_ [$title]($url), for the tag \`$tag\` at \`$commit\`." \
    "The nightly \`cran-release.yaml\` publishes it once Posit's package manager serves the version." ""
fi

# --- the tag ------------------------------------------------------------------

if [ -n "$dry_run" ] && [ -n "$stops" ]; then
  notice "Dry run" "A real run stops before tagging: $tag exists at $stops."
  summary "### Tag" "" "Dry run: a real run stops before drafting or tagging, because \`$tag\` exists at \`$stops\`." ""
  exit 0
fi

group "Tag: $tag at $commit"
say "Message of the tag $tag:"
cat "$message"
if [ -n "$dry_run" ]; then
  endgroup
  notice "Dry run" "Would tag $commit as $tag${moves:+, moving it from $moves}; nothing was tagged or pushed."
  summary "### Tag" "" "Dry run: a real run tags \`$commit\` as \`$tag\`${moves:+, moving it from \`$moves\`}, with this message:" "" \
    '````markdown' "$(cat "$message")" '````' ""
  exit 0
fi

# The default cleanup would drop the "## ..." subheadings as comment lines.
# Only a run with --retag gets here with an existing tag, which it moves.
push_failed() {
  cat "$work/git.err" >&2
  fail "Tag" "Pushing the tag failed" "Tagging $commit as $tag, or pushing the tag, failed: $(head -n 1 "$work/git.err"). The draft release targets $commit." "$work/git.err" -- \
    "If someone pushed the tag meanwhile, find out which commit CRAN is to get before anything else; this run uploaded nothing." \
    "Otherwise check that the job's token may push tags (\`contents: write\`), and dispatch again, with \`retag\` only if the tag exists by now and CRAN never received this version."
}
if [ -n "$moves" ]; then
  say "Moving $tag from $moves to $commit."
  git tag -a -f "$tag" --cleanup=whitespace -F "$message" 2>"$work/git.err" || push_failed
  git push --force origin "refs/tags/$tag" 2>"$work/git.err" || push_failed
else
  git tag -a "$tag" --cleanup=whitespace -F "$message" 2>"$work/git.err" || push_failed
  git push origin "refs/tags/$tag" 2>"$work/git.err" || push_failed
fi
endgroup
notice "Tagged" "Tagged $commit as $tag."
summary "### Tag" "" "Tagged \`$commit\` as \`$tag\`." ""
