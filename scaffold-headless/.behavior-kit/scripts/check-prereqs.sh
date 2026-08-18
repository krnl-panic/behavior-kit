#!/usr/bin/env bash
set -euo pipefail

# Phase gate for the centralized, multi-project behavior kit. Confirms the
# constitution is ratified and carries a Project registry, and — when a project
# is named — that the project resolves to a real git repo. Specs are plain
# directories and worktrees are always created by the kit, so there is no
# spec-clone check and no in-tree branch enforcement here.
#
# Usage: check-prereqs.sh [phase] [project]
#   phase   ∈ {session, specify, plan, behaviors, implement, monitor, epic, quarterback}
#   project — optional project name to validate against the registry.
#   omitted phase = constitution-only checks (legacy behavior).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASE="${1:-}"
PROJECT="${2:-}"
CONSTITUTION=".behavior-kit/memory/constitution.md"

if [[ ! -f "$CONSTITUTION" ]]; then
  echo "Error: Constitution not found. Run /bk.constitution first." >&2
  exit 1
fi

if ! grep -q '^Ratified:' "$CONSTITUTION"; then
  echo "Error: Constitution has not been ratified. Run /bk.constitution first." >&2
  exit 1
fi

if ! grep -qE '^Project:' "$CONSTITUTION"; then
  echo "Error: Constitution has no Project registry. Run /bk.constitution to record at least one 'Project: <name> | repo=... | specs=... | worktrees=...' line." >&2
  exit 1
fi

case "$PHASE" in
  ""|session|specify|plan|behaviors|implement|monitor|epic|quarterback)
    ;;
  *)
    echo "Error: unknown phase '$PHASE' passed to check-prereqs.sh." >&2
    exit 1
    ;;
esac

# When a project is named, validate it resolves (also asserts its repo is a git
# clone). resolve-project.sh emits its own descriptive error.
if [[ -n "$PROJECT" ]]; then
  "$SCRIPT_DIR/resolve-project.sh" "$PROJECT" >/dev/null
fi

exit 0
