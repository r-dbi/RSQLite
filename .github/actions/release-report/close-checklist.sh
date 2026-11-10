#!/usr/bin/env bash
# Close the checklist issue of each release that .github/workflows/cran-release.yaml published,
# with a comment that links the run.
# Process: the header of .github/workflows/cran-submission.yaml
#
# The checklist issue of `<package> <version>` is an open issue whose body carries
# `<!-- release-checklist: <package> <version> -->`, opened by an owner, member or collaborator of the repository,
# as release-report.sh finds it.
# Anyone can open an issue, so an issue by anyone else is left alone, whatever its body carries;
# when only such issues carry the marker, the script warns about them.
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

# The same three functions as in release-report.sh, which finds the issue it reports to with them.
# The open issues whose body carries <text>, newest first, one `<number> <author_association>` per line.
# The issues endpoint lists pull requests too; they carry `pull_request`.
marked_issues() { # <text>
  local text=${1//\\/\\\\}
  text=${text//\"/\\\"}
  "$gh" api --paginate "repos/$repo/issues?state=open&per_page=100" \
    --jq ".[] | select((.pull_request | not) and ((.body // \"\") | contains(\"$text\"))) | \"\\(.number) \\(.author_association)\""
}
# Anyone can open an issue that carries the marker, so only the issues of an owner, a member or a collaborator
# of the repository count: the checklist issue is opened by a person with access to the repository.
trusted() { awk '$2 == "OWNER" || $2 == "MEMBER" || $2 == "COLLABORATOR" { print $1 }'; }
# When none of the <marked issues> counts, warns about them, so that an ignored checklist issue does not go unnoticed.
warn_ignored() { # <text> <marked issues>
  local list
  list=$(printf '%s\n' "$2" | awk 'NF { printf "%s#%s (%s)", sep, $1, $2; sep = ", " }')
  [ -z "$list" ] || echo "::warning title=Checklist issue ignored::Open issues carry $1 but none was opened by an owner, member or collaborator of the repository, so none is the checklist issue: $list. The checklist issue must be opened by a person with access to the repository; an issue that a workflow or a bot opened does not count."
}

while read -r pkg version; do
  [ -n "$pkg" ] || continue
  marker="<!-- release-checklist: $pkg $version -->"
  marked=$(marked_issues "$marker")
  issues=$(printf '%s\n' "$marked" | trusted)
  if [ -z "$issues" ]; then
    warn_ignored "$marker" "$marked"
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
