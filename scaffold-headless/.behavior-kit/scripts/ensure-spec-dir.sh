#!/usr/bin/env bash
set -euo pipefail

# Usage: ensure-spec-dir.sh <project> <TICKET>
#   <project> — a project name from the constitution registry (e.g. myapp, web).
#   <TICKET>  — a Jira issue key like PROJ-123 (uppercase project + number).
#
# Specs are PLAIN DIRECTORIES under the project's specs path: <specs>/<TICKET>/.
# No git, no branch, no push — spec.md / plan.md / behaviors.md / review.md are
# working notes written straight to disk. This resolves the per-ticket spec
# directory, creates it if missing, and prints two informational lines followed
# by the absolute spec directory as its LAST line.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${1:?Usage: ensure-spec-dir.sh <project> <TICKET> (e.g. ensure-spec-dir.sh myapp PROJ-123)}"
TICKET="${2:?Usage: ensure-spec-dir.sh <project> <TICKET> (e.g. ensure-spec-dir.sh myapp PROJ-123)}"

if [[ ! "$TICKET" =~ ^[A-Z][A-Z0-9]*-[0-9]+$ ]]; then
  echo "Error: '$TICKET' is not a valid Jira key. Expected something like PROJ-123." >&2
  exit 1
fi

read -r _REPO SPECS _WT <<< "$("$SCRIPT_DIR/resolve-project.sh" "$PROJECT")"

SPEC_DIR="$SPECS/$TICKET"
mkdir -p "$SPEC_DIR"

echo "Project: $PROJECT"
echo "Spec directory: $SPEC_DIR"
echo "$SPEC_DIR"
