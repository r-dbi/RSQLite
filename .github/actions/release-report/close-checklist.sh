#!/usr/bin/env bash
# Close the checklist issue of each release that .github/workflows/cran-release.yaml published,
# with a comment that links the run.
# Process: the header of .github/workflows/cran-submission.yaml
#
# The checklist issue of `<package> <version>` is the open issue whose body carries
# `<!-- release-checklist: <package> <version> -->`.
# A release without such an issue is a notice, and success: there is nothing to close.
#
# Usage:
#   close-checklist.sh
#
# Environment:
#   GH_TOKEN, GH_REPO     the token and the repository, owner/name
#   GH                    the gh command, default `gh`; release-report-test.sh stubs it
#   PUBLISHED             one `<package> <version>` per line, the `published` output of .github/actions/cran-release
#   RUN_URL               the run that published the releases, linked in the comment

set -euo pipefail

[ $# -eq 0 ] || {
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}
repo=${GH_REPO:?}
gh=${GH:-gh}

while read -r pkg version; do
  [ -n "$pkg" ] || continue
  marker="<!-- release-checklist: $pkg $version -->"
  # The issues endpoint lists pull requests too; they carry `pull_request`.
  issues=$("$gh" api --paginate "repos/$repo/issues?state=open&per_page=100" \
    --jq ".[] | select((.pull_request | not) and ((.body // \"\") | contains(\"$marker\"))) | .number")
  if [ -z "$issues" ]; then
    echo "::notice title=No checklist issue::No open issue carries $marker; nothing to close."
    continue
  fi
  for n in $issues; do
    "$gh" api "repos/$repo/issues/$n/comments" \
      -f body="$pkg $version is on Posit's package manager, and the [run](${RUN_URL:-}) published its release. Closing the checklist." --jq .html_url
    "$gh" api -X PATCH "repos/$repo/issues/$n" -f state=closed -f state_reason=completed --jq .html_url
    echo "::notice title=Checklist closed::Closed #$n for $pkg $version."
  done
done <<<"${PUBLISHED:-}"
