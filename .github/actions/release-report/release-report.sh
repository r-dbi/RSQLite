#!/usr/bin/env bash
# Post a workflow's result to the open release pull request, or to the release's checklist issue,
# as one comment per workflow that later runs update in place.
# Process: the header of .github/workflows/cran-submission.yaml
#
# The target is the open pull request whose head is the ref the run was started on,
# or, when ISSUE_MARKER is set, the newest open issue whose body carries that text instead,
# among the issues of an owner, member or collaborator of the repository:
# the checklist issue, which stays open from the cut until the release is published.
# Anyone can open an issue, so an issue by anyone else is never the target;
# when only such issues carry the text, the script warns about them.
# Without a target, the script says so and succeeds: there is nothing to report to.
# The comment is found by the hidden marker `<!-- release-report: <key> -->`
# among the comments of github-actions[bot].
#
# Usage:
#   release-report.sh <key> <title>
#
# Environment:
#   GH_TOKEN, GH_REPO     the token and the repository, owner/name
#   GH                    the gh command, default `gh`; release-report-test.sh stubs it
#   RESULTS               one `<job>=<result>` per line, as `needs.<job>.result` gives it
#   DETAILS               Markdown appended below the job results, may be empty
#   ISSUE_MARKER          report to the open issue whose body carries this text, not to a pull request
#   GITHUB_SERVER_URL, GITHUB_RUN_ID, GITHUB_RUN_NUMBER, GITHUB_RUN_ATTEMPT,
#   GITHUB_REF_NAME, GITHUB_SHA, GITHUB_EVENT_NAME
#                         the run that is reported

set -euo pipefail

[ $# -eq 2 ] || {
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}
key=$1
title=$2
repo=${GH_REPO:?}
gh=${GH:-gh}
owner=${repo%%/*}

# The same three functions as in close-checklist.sh, which selects the issues it closes with them.
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

if [ -n "${ISSUE_MARKER:-}" ]; then
  marked=$(marked_issues "$ISSUE_MARKER")
  pr=$(printf '%s\n' "$marked" | trusted | sed -n 1p)
  [ -n "$pr" ] || warn_ignored "$ISSUE_MARKER" "$marked"
  what="issue of an owner, member or collaborator whose body carries $ISSUE_MARKER"
else
  pr=$("$gh" api "repos/$repo/pulls?state=open&head=$owner:$GITHUB_REF_NAME&per_page=1" --jq '.[0].number // empty')
  what="pull request has the head $GITHUB_REF_NAME"
fi
if [ -z "$pr" ]; then
  echo "::notice title=Nothing to report to::No open $what; nothing was posted."
  exit 0
fi

overall=success
while IFS='=' read -r job result; do
  [ -n "$job" ] || continue
  case "$result" in
    failure) overall=failure ;;
    cancelled) [ "$overall" = failure ] || overall=cancelled ;;
  esac
done <<<"${RESULTS:-}"
case "$overall" in
  success) icon="✅" ;;
  failure) icon="❌" ;;
  *) icon="⚠️" ;;
esac

run_url="$GITHUB_SERVER_URL/$repo/actions/runs/$GITHUB_RUN_ID"
marker="<!-- release-report: $key -->"
body=$(mktemp)
trap 'rm -f "$body"' EXIT
{
  echo "$marker"
  echo "### $icon $title: $overall"
  echo
  echo "Run [#$GITHUB_RUN_NUMBER]($run_url) (attempt ${GITHUB_RUN_ATTEMPT:-1}, $GITHUB_EVENT_NAME) on \`$GITHUB_REF_NAME\` at \`${GITHUB_SHA:0:10}\`, $(date -u '+%Y-%m-%d %H:%M UTC')."
  echo
  while IFS='=' read -r job result; do
    [ -n "$job" ] || continue
    echo "- \`$job\`: $result"
  done <<<"${RESULTS:-}"
  if [ -n "${DETAILS:-}" ]; then
    echo
    printf '%s\n' "$DETAILS"
  fi
  echo
  echo "The run's summary page has the details. Later runs of this workflow update this comment."
} >"$body"

id=$("$gh" api --paginate "repos/$repo/issues/$pr/comments?per_page=100" \
  --jq ".[] | select(.user.login == \"github-actions[bot]\" and (.body | startswith(\"$marker\"))) | .id" | head -n 1)
if [ -n "$id" ]; then
  "$gh" api -X PATCH "repos/$repo/issues/comments/$id" -F "body=@$body" --jq .html_url
  echo "Updated the comment on #$pr."
else
  "$gh" api "repos/$repo/issues/$pr/comments" -F "body=@$body" --jq .html_url
  echo "Posted a comment on #$pr."
fi
