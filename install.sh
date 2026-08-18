#!/usr/bin/env bash
set -euo pipefail

# behavior-kit installer
# Usage:
#   Install into existing repo:  curl -fsSL ...install.sh | bash
#   Install locally (hidden):    curl -fsSL ...install.sh | bash -s -- --local
#   Create new project:          curl -fsSL ...install.sh | bash -s -- --init <project-name>
#   Update existing install:     curl -fsSL ...install.sh | bash -s -- --update
#   Headless workspace install:  curl -fsSL ...install.sh | bash -s -- --headless [root]
#
# Two modes:
#   per-repo (default) — installs into a git repo; specs live at specs/NNN-slug/,
#     worktrees at .worktrees/NNN-slug/, one project per repo.
#   headless (--headless) — installs into a workspace root that need NOT be a git
#     repo (e.g. ~/dev). One kit serves many projects via the constitution's
#     Project registry; specs are plain dirs at <specs>/<TICKET>/ and worktrees
#     live under <worktrees>/, both outside the project repos. Assumes Jira +
#     an Atlassian MCP for the ticket-seeded phases.

REPO="krnl-panic/behavior-kit"
BRANCH="main"
BASE_URL="${BEHAVIOR_KIT_BASE_URL:-https://raw.githubusercontent.com/${REPO}/${BRANCH}/scaffold}"
# The headless overlay is a sibling of the per-repo scaffold, so derive it from
# whatever BASE_URL points at (works for https and for the file:// URLs tests use).
HEADLESS_URL="${BEHAVIOR_KIT_HEADLESS_URL:-${BASE_URL%/scaffold}/scaffold-headless}"
# Files shared by both modes live in scaffold/ only, so keep its URL around.
SCAFFOLD_URL="$BASE_URL"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
DIM='\033[2m'
NC='\033[0m'

info() { echo -e "${GREEN}[behavior-kit]${NC} $1"; }
warn() { echo -e "${YELLOW}[behavior-kit]${NC} $1"; }
dim() { echo -e "${DIM}  $1${NC}"; }

# Parse flags
INIT=false
LOCAL=false
UPDATE=false
HEADLESS=false
PROJECT_NAME=""
ROOT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --init)
      INIT=true
      PROJECT_NAME="${2:?Usage: install.sh --init <project-name>}"
      shift 2
      ;;
    --local)
      LOCAL=true
      shift
      ;;
    --update)
      UPDATE=true
      shift
      ;;
    --headless)
      HEADLESS=true
      shift
      # An optional non-flag argument after --headless is the workspace root.
      if [[ $# -gt 0 && "$1" != -* ]]; then ROOT="$1"; shift; fi
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --update and --init are mutually exclusive (one creates a project, the other
# refreshes an existing install).
if $UPDATE && $INIT; then
  echo "Error: --update and --init can't be used together." >&2
  exit 1
fi

# --headless installs a workspace, not a project, so the project-shaped flags
# don't apply: --init creates a git repo, --local hides files from a git index,
# and a headless root has neither.
if $HEADLESS && $INIT; then
  echo "Error: --headless and --init can't be used together (--init creates a git project; --headless installs a workspace root)." >&2
  exit 1
fi
if $HEADLESS && $LOCAL; then
  echo "Error: --headless and --local can't be used together (--local hides files from a git index; a headless root need not be a git repo)." >&2
  exit 1
fi
if ! $HEADLESS && [[ -n "$ROOT" ]]; then
  echo "Error: a workspace root argument is only valid with --headless." >&2
  exit 1
fi

if $HEADLESS; then
  ROOT="${ROOT:-$PWD}"
  ROOT="${ROOT/#\~/$HOME}"
  if [[ ! -d "$ROOT" ]]; then
    echo "Error: workspace root '$ROOT' does not exist. Create it first, or pass another path." >&2
    exit 1
  fi
  cd "$ROOT"
  ROOT="$PWD"
  BASE_URL="$HEADLESS_URL"
fi

# --init: create new project directory and git repo
if $INIT; then
  if [[ -d "$PROJECT_NAME" ]]; then
    echo "Error: directory '$PROJECT_NAME' already exists." >&2
    exit 1
  fi
  info "Creating project: $PROJECT_NAME"
  mkdir -p "$PROJECT_NAME"
  cd "$PROJECT_NAME"
  git init -b main --quiet
  cat > .gitignore <<'GITIGNORE'
# OS
.DS_Store
Thumbs.db

# Editors
.vscode/
.idea/
*.swp
*.swo

# Dependencies
node_modules/
vendor/
__pycache__/

# Environment
.env
.env.local
GITIGNORE
  mkdir -p specs
elif ! $HEADLESS; then
  # Verify we're in a git repo. Headless roots are deliberately exempt: the kit
  # lives at the workspace root and only ever touches git inside the project
  # repos named in the registry (always as `git -C <repo>`).
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: not a git repository. Use --init <name> to create a new project, --headless to install a workspace root, or run from an existing repo." >&2
    exit 1
  fi
fi

if $UPDATE; then
  info "Updating behavior-kit to latest from ${BRANCH}..."
else
  info "Installing behavior-kit..."
fi

# Files to install (relative to scaffold/). Order matters only for readability —
# every file is independently downloaded.
FILES=(
  ".claude/commands/bk.constitution.md"
  ".claude/commands/bk.specify.md"
  ".claude/commands/bk.plan.md"
  ".claude/commands/bk.behaviors.md"
  ".claude/commands/bk.implement.md"
  ".claude/commands/bk.iterate.md"
  ".claude/commands/bk.session.md"
  ".claude/commands/bk.monitor.md"
  ".claude/commands/bk.quarterback.md"
  ".claude/agents/bk-specify.md"
  ".claude/agents/bk-plan.md"
  ".claude/agents/bk-behaviors.md"
  ".claude/agents/bk-implement.md"
  ".claude/agents/implementation-agent.md"
  ".claude/agents/bk-enhance.md"
  ".claude/agents/bk-verify.md"
  ".claude/agents/pr-monitor.md"
  ".claude/agents/bk-integrate.md"
  ".cursor/rules/bk-constitution.mdc"
  ".cursor/rules/bk-specify.mdc"
  ".cursor/rules/bk-plan.mdc"
  ".cursor/rules/bk-behaviors.mdc"
  ".cursor/rules/bk-implement.mdc"
  ".cursor/rules/bk-iterate.mdc"
  ".cursor/rules/bk-session.mdc"
  ".agents/skills/bk-constitution/SKILL.md"
  ".agents/skills/bk-specify/SKILL.md"
  ".agents/skills/bk-plan/SKILL.md"
  ".agents/skills/bk-behaviors/SKILL.md"
  ".agents/skills/bk-implement/SKILL.md"
  ".agents/skills/bk-iterate/SKILL.md"
  ".agents/skills/bk-session/SKILL.md"
  ".agents/skills/bk-monitor/SKILL.md"
  ".agents/skills/bk-quarterback/SKILL.md"
  ".behavior-kit/memory/constitution.md"
  ".behavior-kit/templates/spec-template.md"
  ".behavior-kit/templates/plan-template.md"
  ".behavior-kit/templates/behavior-template.md"
  ".behavior-kit/templates/review-template.md"
  ".behavior-kit/scripts/init-feature.sh"
  ".behavior-kit/scripts/init-session.sh"
  ".behavior-kit/scripts/check-prereqs.sh"
  ".behavior-kit/scripts/setup-worktrees.sh"
)

# The headless overlay is a complete tree of its own: multi-project scripts, the
# registry-bearing constitution, the ticket-keyed phases, and the roster.
HEADLESS_FILES=(
  ".claude/commands/bk.constitution.md"
  ".claude/commands/bk.specify.md"
  ".claude/commands/bk.plan.md"
  ".claude/commands/bk.behaviors.md"
  ".claude/commands/bk.implement.md"
  ".claude/commands/bk.session.md"
  ".claude/commands/bk.monitor.md"
  ".claude/commands/bk.epic.md"
  ".claude/agents/bk-specify.md"
  ".claude/agents/bk-plan.md"
  ".claude/agents/bk-behaviors.md"
  ".claude/agents/bk-implement.md"
  ".claude/agents/implementation-agent.md"
  ".claude/agents/bk-enhance.md"
  ".claude/agents/bk-verify.md"
  ".claude/agents/pr-monitor.md"
  ".claude/agents/bk-integrate.md"
  ".behavior-kit/memory/constitution.md"
  ".behavior-kit/templates/spec-template.md"
  ".behavior-kit/templates/plan-template.md"
  ".behavior-kit/templates/behavior-template.md"
  ".behavior-kit/templates/review-template.md"
  ".behavior-kit/scripts/resolve-project.sh"
  ".behavior-kit/scripts/check-prereqs.sh"
  ".behavior-kit/scripts/ensure-spec-dir.sh"
  ".behavior-kit/scripts/add-group-worktree.sh"
  ".behavior-kit/scripts/init-session.sh"
  ".behavior-kit/scripts/setup-worktrees.sh"
  "ROSTER-BOOTSTRAP-PROMPT.md"
)

# One mode-aware copy, kept in scaffold/ and installed by both modes, so its
# doctrine can never drift between them.
SHARED_FILES=(
  ".claude/commands/bk.quarterback.md"
)

HEADLESS_SCRIPTS=(
  ".behavior-kit/scripts/resolve-project.sh"
  ".behavior-kit/scripts/check-prereqs.sh"
  ".behavior-kit/scripts/ensure-spec-dir.sh"
  ".behavior-kit/scripts/add-group-worktree.sh"
  ".behavior-kit/scripts/init-session.sh"
  ".behavior-kit/scripts/setup-worktrees.sh"
)

if $HEADLESS; then
  FILES=("${HEADLESS_FILES[@]}")
fi

# Files that hold user-edited state. On --update we leave these alone if the
# user already has a copy; on fresh install they're seeded from the scaffold.
PRESERVE_ON_UPDATE=(
  ".behavior-kit/memory/constitution.md"
)

is_preserved() {
  local needle="$1"
  for f in "${PRESERVE_ON_UPDATE[@]}"; do
    [[ "$f" == "$needle" ]] && return 0
  done
  return 1
}

# Install one file from a given base URL. A headless install lands in a live
# workspace that may already be in use, so it never destroys a differing file:
# the previous version is kept alongside as <name>.bak-<n>. The constitution
# carries the Project registry, so headless always preserves an existing one.
install_file() {
  local base="$1" file="$2"
  if { $UPDATE || $HEADLESS; } && is_preserved "$file" && [[ -f "$file" ]]; then
    dim "$file (preserved)"
    return 0
  fi
  mkdir -p "$(dirname "$file")"
  if $HEADLESS && [[ -f "$file" ]]; then
    local tmp n
    tmp="$(mktemp)"
    curl -fsSL "${base}/${file}" -o "$tmp"
    if cmp -s "$tmp" "$file"; then
      rm -f "$tmp"
      dim "$file (unchanged)"
      return 0
    fi
    n=1
    while [[ -e "$file.bak-$n" ]]; do n=$((n + 1)); done
    cp "$file" "$file.bak-$n"
    mv "$tmp" "$file"
    dim "$file (previous kept as $(basename "$file").bak-$n)"
    return 0
  fi
  curl -fsSL "${base}/${file}" -o "$file"
  dim "$file"
}

for file in "${FILES[@]}"; do
  install_file "$BASE_URL" "$file"
done

# Shared files always come from scaffold/, whichever mode we are installing.
if $HEADLESS; then
  for file in "${SHARED_FILES[@]}"; do
    install_file "$SCAFFOLD_URL" "$file"
  done
fi

# Make scripts executable
if $HEADLESS; then
  chmod +x "${HEADLESS_SCRIPTS[@]}"
else
  chmod +x .behavior-kit/scripts/init-feature.sh \
           .behavior-kit/scripts/init-session.sh \
           .behavior-kit/scripts/check-prereqs.sh \
           .behavior-kit/scripts/setup-worktrees.sh
fi

# --local: hide bk files from git via .git/info/exclude
if $LOCAL; then
  EXCLUDE_PATHS=(
    ".claude/commands/bk.*.md"
    ".claude/agents/bk-*.md"
    ".claude/agents/implementation-agent.md"
    ".claude/agents/pr-monitor.md"
    ".cursor/rules/bk-*.mdc"
    ".agents/skills/bk-*/"
    ".behavior-kit/"
  )

  EXCLUDE_FILE="$(git rev-parse --git-dir)/info/exclude"
  mkdir -p "$(dirname "$EXCLUDE_FILE")"
  touch "$EXCLUDE_FILE"

  for pattern in "${EXCLUDE_PATHS[@]}"; do
    if ! grep -qF "$pattern" "$EXCLUDE_FILE" 2>/dev/null; then
      echo "$pattern" >> "$EXCLUDE_FILE"
    fi
  done

  info "Added patterns to .git/info/exclude (local only, won't affect teammates)"
fi

# Create the working directories. Headless keeps specs and worktrees at the
# workspace root, outside every project repo; per-repo keeps specs in the repo.
mkdir -p specs
if $HEADLESS; then mkdir -p worktrees; fi

# --init: make initial commit
if $INIT; then
  git add .gitignore specs/
  git commit --quiet -m "Initial commit"
  info "Created git repo with initial commit on main"
fi

echo ""
if $UPDATE; then
  info "Updated. Constitution and specs/ left untouched; everything else refreshed from ${BRANCH}."
elif $HEADLESS; then
  info "Headless workspace installed at $ROOT"
  dim "/bk.constitution  — Principles + the Project registry (run this first)"
  dim "/bk.specify        — Spec a ticket        (/bk.specify <project> <TICKET>)"
  dim "/bk.plan           — Research context     (/bk.plan <project> <TICKET>)"
  dim "/bk.behaviors      — Testable behaviors   (/bk.behaviors <project> <TICKET>)"
  dim "/bk.implement      — Orchestrate groups   (/bk.implement <project> <TICKET>)"
  dim "/bk.session        — One-off session      (/bk.session <project> [purpose])"
  dim "/bk.monitor        — Drive a PR to merge-ready"
  dim "/bk.epic           — Decompose an epic across its children"
  dim "/bk.quarterback    — Orchestrate a multi-ticket initiative"
  echo ""
  info "next steps:"
  dim "1. Register your projects in .behavior-kit/memory/constitution.md — one line each:"
  dim "     Project: <name> | repo=~/dev/<repo> | specs=~/dev/specs/<name> | worktrees=~/dev/worktrees/<name>"
  dim "   Registry paths may start with ~ (expanded) but NOT \$HOME (taken literally)."
  dim "2. .behavior-kit/scripts/setup-worktrees.sh"
  dim "3. .behavior-kit/scripts/check-prereqs.sh quarterback"
  dim "4. Restart your agent from $ROOT — commands and agents register at session start."
  echo ""
  dim "Ticket-seeded phases assume Jira reachable through an Atlassian MCP."
else
  info "Done! Commands available:"
  dim "/bk.constitution  — Set up project principles"
  dim "/bk.specify        — Write a feature spec"
  dim "/bk.plan           — Research codebase context"
  dim "/bk.behaviors      — Decompose into testable behaviors"
  dim "/bk.implement      — Execute behaviors test-first"
  dim "/bk.iterate        — Address PR review feedback"
  dim "/bk.session        — Lightweight pairing / one-off session"
  dim "/bk.monitor        — Drive a PR's automated review loop to merge-ready"
  dim "/bk.quarterback    — Orchestrate a multi-feature initiative"
  echo ""
  dim "Codex users: slash names use hyphens (e.g. /bk-specify, /bk-session)."
  echo ""
  info "Start with: /bk.constitution"
fi
