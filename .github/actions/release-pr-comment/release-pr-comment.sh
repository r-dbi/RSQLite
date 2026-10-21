#!/usr/bin/env bash
# Post a workflow's result to the open release pull request,
# as one comment per workflow that later runs update in place.
# Process: the header of .github/workflows/cran-submission.yaml
#
# The pull request is the open one whose head is the ref the run was started on;
# without one, the open pull request carrying the label PR_LABEL, when that is set.
# Without either, the script says so and succeeds: there is nothing to report to.
# The comment is found by the hidden marker `<!-- release-report: <key> -->`
# among the comments of github-actions[bot].
#
# Usage:
#   release-pr-comment.sh <key> <title>
#
# Environment:
#   GH_TOKEN, GH_REPO     the token and the repository, owner/name
#   GH                    the gh command, default `gh`; release-pr-comment-test.sh stubs it
#   RESULTS               one `<job>=<result>` per line, as `needs.<job>.result` gives it
#   DETAILS               Markdown appended below the job results, may be empty
#   PR_LABEL              the label of the fallback pull request, may be empty
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

pr=$("$gh" api "repos/$repo/pulls?state=open&head=$owner:$GITHUB_REF_NAME&per_page=1" --jq '.[0].number // empty')
if [ -z "$pr" ] && [ -n "${PR_LABEL:-}" ]; then
  pr=$("$gh" api --paginate "repos/$repo/pulls?state=open&per_page=100" \
    --jq "[.[] | select(any(.labels[]; .name == \"$PR_LABEL\"))][0].number // empty" | head -n 1)
fi
if [ -z "$pr" ]; then
  echo "::notice title=No release pull request::No open pull request has the head $GITHUB_REF_NAME${PR_LABEL:+ or the label "$PR_LABEL"}; nothing was posted."
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
