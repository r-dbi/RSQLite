#!/usr/bin/env bash
# Copied from duckdb/duckdb-r's scripts/cran-release.sh at 86ac17f6b.
# Publish the draft GitHub releases of CRAN submissions once Posit's package manager serves their version.
# Process: the header of .github/workflows/cran-submission.yaml
#
# .github/workflows/cran-submission.yaml drafts a release for every submission,
# and ends its notes with a marker that GitHub does not render:
#
#   <!-- cran-submission: <package> <version> -->
#
# This script lists the draft releases whose notes carry that marker and whose tag is
# `v<version>`, and checks each version against the source index of P3M's CRAN snapshot
# `latest`, the index `fledge:::release_after_cran_built_binaries()` reads with
# `utils::available.packages(repos = "https://packagemanager.posit.co/cran/latest")`:
# the version is out when the index lists the package at exactly that version.
# A version that is out is published as the latest release, addressed by the release's id,
# after checking that the draft is the only one with the marker for its tag,
# that it carries the tarball `<package>_<version>.tar.gz`, which cran-submission.yaml attaches only after a successful upload,
# and that the tag exists and points at the commit the draft targets;
# several drafts, a missing tarball or a missing or moved tag are reported, with how to resolve them, and nothing is published.
# A version that is not out yet, or no draft at all, is a line in the report and success,
# so a nightly run stays green while it waits.
#
# Usage:
#   .github/actions/cran-release/cran-release.sh [--dry-run]
#
# --dry-run checks everything and publishes nothing, saying what it would publish.
# With GITHUB_OUTPUT set, the script writes `published`, one `<package> <version>` per line
# for each release it published, which cran-release.yaml uses to close the checklist issue.
# Exit status: 0 when nothing failed, 1 when a draft could not be published, 2 on a usage error.
#
# Environment:
#   GH_REPO              the repository, owner/name; defaults to GITHUB_REPOSITORY
#   GH                   the gh command, default `gh`; .github/actions/cran-release/cran-release-test.sh stubs it
#   P3M_REPO_URL         the CRAN repository to check, default https://packagemanager.posit.co/cran/latest;
#                        the test points it at a local server
#   GITHUB_ACTIONS, GITHUB_STEP_SUMMARY, GITHUB_SERVER_URL, GITHUB_REPOSITORY
#                        the log's groups and annotations, the report, and the commit links
#                        (.github/actions/cran-lib/cran-lib.sh)

set -euo pipefail

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../cran-lib/cran-lib.sh
. "$(dirname "$0")/../cran-lib/cran-lib.sh"

dry_run=''
case "${1:-}" in
  '') ;;
  --dry-run) dry_run=1 ;;
  -h | --help)
    sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 2
    ;;
esac
[ $# -le 1 ] || exit 2

repo=${GH_REPO:-${GITHUB_REPOSITORY:-}}
[ -n "$repo" ] || {
  echo "Set GH_REPO (or GITHUB_REPOSITORY) to the repository, owner/name." >&2
  exit 2
}
gh=${GH:-gh}
p3m=${P3M_REPO_URL:-https://packagemanager.posit.co/cran/latest}
p3m=${p3m%/}
index_url=$p3m/src/contrib/PACKAGES.gz

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

summary "## CRAN release${dry_run:+: dry run}" ""
[ -z "$dry_run" ] || summary "Dry run: nothing is published." ""

# --- the drafts -------------------------------------------------------------

group "Drafts: the releases cran-submission.yaml drafted in $repo"
# A draft has no tag yet, so its pending tag name is read from the release list.
# One line per draft with the marker: tag, package, version, target, URL,
# whether the draft carries the submitted tarball as an asset, and the release's id.
# shellcheck disable=SC2016  # a jq program, with jq's own $r
if ! "$gh" api --paginate "repos/$repo/releases?per_page=100" --jq '
  .[] | select(.draft) | . as $r
  | ($r.body // "") | capture("<!-- cran-submission: (?<pkg>[^ ]+) (?<ver>[^ ]+) -->") | . as $m
  | [$r.tag_name, $m.pkg, $m.ver, $r.target_commitish, $r.html_url,
     any($r.assets[]?; .name == "\($m.pkg)_\($m.ver).tar.gz"), $r.id] | @tsv' >"$work/drafts" 2>"$work/gh.err"; then
  cat "$work/gh.err" >&2
  fail "Drafts" "The releases cannot be listed" "\`gh api repos/$repo/releases\` failed: $(head -n 1 "$work/gh.err")" "$work/gh.err" -- \
    "Check that the token may read the repository's releases; drafts need \`contents: write\`." \
    "Rerun the workflow; the next nightly run tries again in any case."
fi
n=0
while IFS=$'\t' read -r tag pkg version target url tarball id; do
  if [ "$tag" != "v$version" ]; then
    say "  skipped: $url, tag $tag, which is not v$version as its marker says"
    continue
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$tag" "$pkg" "$version" "$target" "$url" "$tarball" "$id" >>"$work/matching"
  val "draft" "$pkg $version, tag $tag, target $target, $url"
  n=$((n + 1))
done <"$work/drafts"
endgroup
# The tags that more than one of these drafts carries.
[ ! -s "$work/matching" ] || cut -f 1 "$work/matching" | sort | uniq -d >"$work/duplicates"

if [ "$n" -eq 0 ]; then
  say "No draft release of a CRAN submission in $repo."
  summary "No draft release of a CRAN submission: nothing to publish."
  exit 0
fi

# --- P3M --------------------------------------------------------------------

group "P3M: the source index of $p3m"
val "index" "$index_url"
if ! curl --fail --silent --show-error --location --retry 3 --connect-timeout 30 --max-time 300 \
  --output "$work/PACKAGES.gz" "$index_url" 2>"$work/curl.err" ||
  ! gzip -dc "$work/PACKAGES.gz" >"$work/PACKAGES" 2>>"$work/curl.err"; then
  cat "$work/curl.err" >&2
  fail "P3M" "P3M cannot be read" "Reading $index_url failed: $(head -n 1 "$work/curl.err")" "$work/curl.err" -- \
    "Check that $index_url answers, for instance with \`curl -sSI $index_url\`." \
    "Nothing was published; the next nightly run tries again, or rerun the workflow once P3M answers."
fi
val "packages" "$(grep -c '^Package:' "$work/PACKAGES" || true)"
endgroup

# The version an index lists for a package, empty when it lists none.
p3m_version() { # <package>
  awk -v p="$1" '
    /^Package:/ { this = ($2 == p) }
    this && /^Version:/ { print $2; exit }' "$work/PACKAGES"
}

# The commit a tag points to on GitHub, peeled; empty when there is no such tag.
tag_commit() { # <tag>
  local ref
  ref=$("$gh" api "repos/$repo/git/matching-refs/tags/$1" --jq ".[] | select(.ref == \"refs/tags/$1\") | .ref") || return 1
  [ -n "$ref" ] || return 0
  "$gh" api "repos/$repo/commits/refs/tags/$1" --jq .sha
}

# The commit a draft targets: cran-submission.yaml sets a full SHA, and anything else is resolved.
target_commit() { # <target>
  if [[ "$1" =~ ^[0-9a-f]{40}$ ]]; then
    printf '%s\n' "$1"
  else
    "$gh" api "repos/$repo/commits/$1" --jq .sha
  fi
}

# --- each draft -------------------------------------------------------------

failed=0
while IFS=$'\t' read -r tag pkg version target url tarball id <&3; do
  title="$pkg $version"
  group "Release: $title"
  val "draft" "$url, id $id"
  val "tag" "$tag"
  val "target" "$target"
  served=$(p3m_version "$pkg")
  val "P3M serves" "${served:-(not listed)}"

  if [ "$served" != "$version" ]; then
    endgroup
    listed="no $pkg"
    [ -z "$served" ] || listed="$pkg $served"
    say "$title is not on P3M yet; checked $index_url, which lists $listed."
    summary "- $title is not on P3M yet; checked $index_url, which lists $listed."
    continue
  fi

  summary "### $title" "" \
    "- Draft release: [$title]($url), tag \`$tag\`" \
    "- Commit $(commit_link "$target"), the draft's target" \
    "- P3M: checked $index_url, which lists $pkg $served"

  # cran-submission.yaml runs one submission at a time and refuses several drafts for a tag,
  # so another one was written by hand, and only a person can tell which one CRAN got.
  if grep -qxF "$tag" "$work/duplicates"; then
    failure "$title" "Several drafts for $tag" "$title is on P3M, and more than one draft release with the marker of cran-submission.yaml carries the tag $tag, this one among them; nothing was published." -- \
      "Find the draft of the run of cran-submission.yaml that submitted $title: it carries the tarball, and its target is the commit that run links." \
      "Delete the other drafts; the next nightly run publishes the one that is left, or rerun this workflow."
    failed=1
    continue
  fi

  # cran-submission.yaml writes the draft and the tag before it builds and uploads,
  # and attaches the tarball only once the upload went through:
  # a draft without it is from a run that failed on the way, whatever P3M serves.
  asset="${pkg}_${version}.tar.gz"
  val "tarball" "$([ "$tarball" = true ] && echo "$asset" || echo "(none)")"
  if [ "$tarball" != true ]; then
    failure "$title" "The submitted tarball is missing" "$title is on P3M, but its draft release carries no asset $asset, which the submission run attaches after a successful upload; nothing was published." -- \
      "Open the run of cran-submission.yaml that submitted $title: its summary says whether the upload went through, and links the commit." \
      "If it did and only attaching failed, attach the run's artifact \`${pkg}_${version}\`: \`gh release upload $tag $asset\`." \
      "If CRAN got $title some other way, attach the tarball CRAN got, and check that the tag and the draft's target are its commit." \
      "The next nightly run publishes the release once the tarball is there, or rerun this workflow."
    failed=1
    continue
  fi
  summary "- Submitted tarball: \`$asset\`, attached to the draft"

  # Draft and tag are written by the same run of cran-submission.yaml, the draft first.
  if ! tagged=$(tag_commit "$tag" 2>"$work/gh.err"); then
    cat "$work/gh.err" >&2
    failure "$title" "The tag $tag cannot be read" "\`gh api\` failed reading the tag: $(head -n 1 "$work/gh.err")" "$work/gh.err" -- \
      "Rerun the workflow; nothing was published."
    failed=1
    continue
  fi
  val "tag points to" "${tagged:-(no tag)}"
  if [ -z "$tagged" ]; then
    failure "$title" "The tag $tag is missing" "$title is on P3M, and its draft release targets $target, but $repo has no tag $tag; nothing was published." -- \
      "cran-submission.yaml drafts the release and then pushes the tag; if that run failed in between, push the tag the submission meant: \`git tag -a $tag $target -m \"$title\" && git push origin $tag\`." \
      "Check first that $target is the commit CRAN got: the submission run's summary links it." \
      "The next nightly run publishes the release once the tag is there, or rerun this workflow."
    failed=1
    continue
  fi
  targeted=$(target_commit "$target" 2>>"$work/gh.err") || targeted=''
  if [ "$tagged" != "$targeted" ]; then
    failure "$title" "The tag $tag points elsewhere" "The tag $tag points to $tagged, and the draft release targets $target; nothing was published." -- \
      "Find out which commit CRAN got: the run of cran-submission.yaml that uploaded $title links it in its summary." \
      "If the tag is right, edit the draft and set its target to the tag; if the draft is right, move the tag: \`git tag -f -a $tag $target -m \"$title\" && git push -f origin $tag\`." \
      "The next nightly run publishes the release once both agree, or rerun this workflow."
    failed=1
    continue
  fi

  if [ -n "$dry_run" ]; then
    endgroup
    notice "Dry run" "Would publish $title ($url) as the latest release; nothing was published."
    summary "- Dry run: a real run publishes the draft as the latest release." ""
    continue
  fi

  # By the release's id: `gh release edit <tag>` would pick any release that carries the tag name.
  if ! "$gh" api -X PATCH "repos/$repo/releases/$id" -F draft=false -f make_latest=true --jq .html_url >"$work/edit.out" 2>"$work/gh.err"; then
    cat "$work/gh.err" >&2
    failure "$title" "Publishing the release failed" "\`gh api -X PATCH repos/$repo/releases/$id\` failed: $(head -n 1 "$work/gh.err")" "$work/gh.err" -- \
      "Check that the token may write releases: the workflow needs \`contents: write\`." \
      "Publish the draft by hand at $url, or rerun this workflow."
    failed=1
    continue
  fi
  endgroup
  notice "Published" "$title is on P3M; published the release $url."
  printf '%s\n' "$title" >>"$work/published"
  summary "- Published as the latest release." ""
done 3<"$work/matching"

if [ -n "${GITHUB_OUTPUT:-}" ] && [ -s "$work/published" ]; then
  { echo "published<<EOF_PUBLISHED"; cat "$work/published"; echo "EOF_PUBLISHED"; } >>"$GITHUB_OUTPUT"
fi
exit "$failed"
