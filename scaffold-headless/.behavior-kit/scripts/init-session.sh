#!/usr/bin/env bash
set -euo pipefail

# Usage: init-session.sh <project> <tag> <slug>
#   <project> — project name from the constitution registry (myapp, web).
#   <tag>     ∈ {fix, dev, chore, refactor, docs, test, ci, build, perf, style, revert}
#             — a conventional-commit-style prefix the agent picked for the session.
#   <slug>    — short kebab-case summary of what the session is about (3-5 words).
#
# Sessions are lightweight: no ticket, no specs/ artifact. Worktrees are
# mandatory: this creates a {tag}/{slug} branch and a matching worktree under the
# project's worktrees path, forked from the project repo's integration branch.
# Sessions never enter plan/behaviors/implement. Ticketed work that warrants a
# spec goes through /bk.specify instead.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${1:?Usage: init-session.sh <project> <tag> <slug>}"
TAG="${2:?Usage: init-session.sh <project> <tag> <slug>}"
SLUG="${3:?Usage: init-session.sh <project> <tag> <slug>}"

# feat is deliberately excluded — new features go through /bk.specify.
case "$TAG" in
  fix|dev|chore|refactor|docs|test|ci|build|perf|style|revert) ;;
  *)
    echo "Error: tag '$TAG' is not one of: fix, dev, chore, refactor, docs, test, ci, build, perf, style, revert." >&2
    exit 1
    ;;
esac

SLUG=$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | tr -s '-')
SLUG=$(echo "$SLUG" | cut -d- -f1-5)
SLUG=${SLUG:0:50}
SLUG=${SLUG#-}
SLUG=${SLUG%-}
if [[ -z "$SLUG" ]]; then
  echo "Error: slug is empty after normalization. Pass 3-5 kebab-case words." >&2
  exit 1
fi

BRANCH="${TAG}/${SLUG}"
read -r REPO _SPECS WT <<< "$("$SCRIPT_DIR/resolve-project.sh" "$PROJECT")"

if git -C "$REPO" show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "Error: branch '$BRANCH' already exists in $REPO. Pick a different slug or check out the existing branch." >&2
  exit 1
fi

WORKTREE_PATH="${WT}/${TAG}-${SLUG}"
if [[ -e "$WORKTREE_PATH" ]]; then
  echo "Error: worktree path '$WORKTREE_PATH' already exists." >&2
  exit 1
fi
mkdir -p "$WT"

if git -C "$REPO" show-ref --verify --quiet refs/heads/main; then
  BASE=main
elif git -C "$REPO" show-ref --verify --quiet refs/heads/master; then
  BASE=master
else
  BASE="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
fi

git -C "$REPO" worktree add -b "$BRANCH" "$WORKTREE_PATH" "$BASE" >/dev/null

echo "Created branch: $BRANCH (from $BASE)"
echo "Created worktree: $WORKTREE_PATH"
echo ""
echo "Next: enter this worktree (EnterWorktree path=$WORKTREE_PATH) — no cd or new session needed."
echo "$WORKTREE_PATH"
