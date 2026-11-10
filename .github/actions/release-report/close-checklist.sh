#!/usr/bin/env bash
# Close the checklist issue of each release that .github/workflows/cran-release.yaml published,
# with a comment that links the run.
# Process: the header of .github/workflows/cran-submission.yaml
#
# The checklist issue of `<package> <version>` is an open issue whose body carries
# `<!-- release-checklist: <package> <version> -->`, opened by an owner, member or collaborator of the repository,
# as release-report.sh finds it.
# Anyone can open an issue, so an issue by anyone else is left alone, whatever its body carries.
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

# The open issues whose body carries <text>, opened by an owner, member or collaborator of the repository:
# the same filter as in release-report.sh.
checklist_issues() { # <text>
  local text=${1//\\/\\\\}
  text=${text//\"/\\\"}
  # The issues endpoint lists pull requests too; they carry `pull_request`.
  "$gh" api --paginate "repos/$repo/issues?state=open&per_page=100" --jq ".[] | select((.pull_request | not)
    and (.author_association == \"OWNER\" or .author_association == \"MEMBER\" or .author_association == \"COLLABORATOR\")
    and ((.body // \"\") | contains(\"$text\"))) | .number"
}

while read -r pkg version; do
  [ -n "$pkg" ] || continue
  marker="<!-- release-checklist: $pkg $version -->"
  issues=$(checklist_issues "$marker")
  if [ -z "$issues" ]; then
    echo "::notice title=No checklist issue::No open issue of an owner, member or collaborator carries $marker; nothing to close."
    continue
  fi
  for n in $issues; do
    "$gh" api "repos/$repo/issues/$n/comments" \
      -f body="$pkg $version is on Posit's package manager, and the [run](${RUN_URL:-}) published its release. Closing the checklist." --jq .html_url
    "$gh" api -X PATCH "repos/$repo/issues/$n" -f state=closed -f state_reason=completed --jq .html_url
    echo "::notice title=Checklist closed::Closed #$n for $pkg $version."
  done
done <<<"${PUBLISHED:-}"
