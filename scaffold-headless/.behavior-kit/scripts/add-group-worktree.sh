#!/usr/bin/env bash
set -euo pipefail

# Usage: add-group-worktree.sh <project> <TICKET> <group-slug> [type]
#   <project>     — project name from the constitution registry (myapp, web).
#   <TICKET>      — Jira issue key like PROJ-123.
#   <group-slug>  — short kebab-case name for a parallel behavior group (e.g. api, ui).
#   [type]        — branch type: feat (default), fix, or dev.
#
# Worktrees are MANDATORY. This always creates (or reuses) a git worktree for the
# group's branch <type>/<TICKET>-<slug> under the project's worktrees path,
# forked from the project repo's integration branch. behavior-kit never works on
# a branch in the project's main checkout. Idempotent: re-running for an existing
# group reuses its branch/worktree. Prints the worktree path as its last line.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${1:?Usage: add-group-worktree.sh <project> <TICKET> <group-slug> [type]}"
TICKET="${2:?Usage: add-group-worktree.sh <project> <TICKET> <group-slug> [type]}"
SLUG="${3:?Usage: add-group-worktree.sh <project> <TICKET> <group-slug> [type]}"
TYPE="${4:-feat}"

case "$TYPE" in
  feat|fix|dev) ;;
  *) echo "Error: type '$TYPE' is not one of: feat, fix, dev." >&2; exit 1 ;;
esac

if [[ ! "$TICKET" =~ ^[A-Z][A-Z0-9]*-[0-9]+$ ]]; then
  echo "Error: '$TICKET' is not a valid Jira key. Expected something like PROJ-123." >&2
  exit 1
fi

# Normalize the slug so branch/dir names stay sane.
SLUG=$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | tr -s '-')
SLUG=$(echo "$SLUG" | cut -d- -f1-5)
SLUG=${SLUG:0:50}
SLUG=${SLUG#-}
SLUG=${SLUG%-}
if [[ -z "$SLUG" ]]; then
  echo "Error: group slug is empty after normalization. Pass a short kebab-case name." >&2
  exit 1
fi

read -r REPO _SPECS WT <<< "$("$SCRIPT_DIR/resolve-project.sh" "$PROJECT")"

SUFFIX="${TICKET}-${SLUG}"
BRANCH="${TYPE}/${SUFFIX}"
WORKTREE_PATH="${WT}/${SUFFIX}"
mkdir -p "$WT"

# Fork from the project repo's integration branch.
if git -C "$REPO" show-ref --verify --quiet refs/heads/main; then
  BASE=main
elif git -C "$REPO" show-ref --verify --quiet refs/heads/master; then
  BASE=master
else
  BASE="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
fi

if [[ -d "$WORKTREE_PATH" ]]; then
  echo "Reusing worktree: $WORKTREE_PATH"
elif git -C "$REPO" show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git -C "$REPO" worktree add "$WORKTREE_PATH" "$BRANCH" >/dev/null
  echo "Created worktree for existing branch: $WORKTREE_PATH"
else
  git -C "$REPO" worktree add -b "$BRANCH" "$WORKTREE_PATH" "$BASE" >/dev/null
  echo "Created branch: $BRANCH (from $BASE)"
  echo "Created worktree: $WORKTREE_PATH"
fi
echo "$WORKTREE_PATH"
