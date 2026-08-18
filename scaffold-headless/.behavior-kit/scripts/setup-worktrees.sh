#!/usr/bin/env bash
set -euo pipefail

# Creates the per-project worktrees directories declared in the constitution's
# Project registry. Worktrees are mandatory in this workspace; each project's
# worktrees live under its own worktrees= path (outside the repo, so nothing needs
# gitignoring). Safe to re-run.
#
# Usage: setup-worktrees.sh

CONSTITUTION=".behavior-kit/memory/constitution.md"
if [[ ! -f "$CONSTITUTION" ]]; then
  echo "Error: Constitution not found. Run /bk.constitution first." >&2
  exit 1
fi

grep -E '^Project:' "$CONSTITUTION" | while IFS= read -r line; do
  name="$(sed -n 's/^Project:[[:space:]]*\([^ |]*\).*/\1/p' <<<"$line")"
  wt="$(sed -n 's/.*worktrees=\([^ |]*\).*/\1/p' <<<"$line")"
  wt="${wt/#\~/$HOME}"
  if [[ -n "$wt" ]]; then
    mkdir -p "$wt"
    echo "Worktrees for '$name': $wt"
  fi
done
