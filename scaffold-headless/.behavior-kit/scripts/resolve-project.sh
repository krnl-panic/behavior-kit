#!/usr/bin/env bash
set -euo pipefail

# Usage: resolve-project.sh <project>
# Resolves a project name (e.g. myapp, web) to its three absolute paths from
# the constitution's Project registry and prints them space-separated on one line:
#
#   <repo> <specs> <worktrees>
#
# The registry lives in the constitution as one line per project:
#   Project: <name> | repo=<abs> | specs=<abs> | worktrees=<abs>
#
# Exits non-zero with a message if the project is unknown, malformed, or its repo
# is not a git repository.

PROJECT="${1:?Usage: resolve-project.sh <project> (e.g. resolve-project.sh myapp)}"
CONSTITUTION="${CONSTITUTION:-.behavior-kit/memory/constitution.md}"

if [[ ! -f "$CONSTITUTION" ]]; then
  echo "Error: Constitution not found at '$CONSTITUTION'. Run /bk.constitution first." >&2
  exit 1
fi

LINE="$(grep -E "^Project:[[:space:]]*${PROJECT}[[:space:]]*\|" "$CONSTITUTION" | head -n1 || true)"
if [[ -z "$LINE" ]]; then
  echo "Error: unknown project '$PROJECT'. Known projects:" >&2
  grep -E '^Project:' "$CONSTITUTION" | sed -E 's/^Project:[[:space:]]*([^ |]+).*/  - \1/' >&2 || true
  echo "Add it via /bk.constitution, or pass one of the names above." >&2
  exit 1
fi

REPO="$(sed -n 's/.*repo=\([^ |]*\).*/\1/p' <<<"$LINE")"
SPECS="$(sed -n 's/.*specs=\([^ |]*\).*/\1/p' <<<"$LINE")"
WT="$(sed -n 's/.*worktrees=\([^ |]*\).*/\1/p' <<<"$LINE")"

REPO="${REPO/#\~/$HOME}"
SPECS="${SPECS/#\~/$HOME}"
WT="${WT/#\~/$HOME}"

if [[ -z "$REPO" || -z "$SPECS" || -z "$WT" ]]; then
  echo "Error: malformed 'Project: $PROJECT' line (need repo=, specs=, worktrees=)." >&2
  exit 1
fi

if ! git -C "$REPO" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Error: project '$PROJECT' repo '$REPO' is not a git repository." >&2
  exit 1
fi

echo "$REPO $SPECS $WT"
