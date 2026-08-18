#!/usr/bin/env bash
# Headless-mode install: a workspace root that is NOT a git repo, serving many
# projects through the constitution's Project registry.

TESTS=(
  test_headless_installs_outside_a_git_repo
  test_headless_creates_specs_and_worktrees
  test_headless_rejects_local
  test_headless_rejects_init
  test_headless_root_argument_requires_headless
  test_headless_missing_root_fails
  test_headless_preserves_constitution_and_backs_up_changes
  test_headless_scripts_resolve_a_registered_project
  test_per_repo_install_still_needs_a_git_repo
  test_quarterback_is_not_duplicated_across_trees
)

# The whole point of the mode: no `git init` here, and it must still succeed.
test_headless_installs_outside_a_git_repo() {
  mkdir -p ws
  capture bash "$INSTALL_SH" --headless ws
  assert_rc_zero
  assert_file_exists ws/.claude/commands/bk.quarterback.md
  assert_file_exists ws/.claude/commands/bk.epic.md
  assert_file_exists ws/.claude/agents/bk-integrate.md
  assert_file_exists ws/.behavior-kit/scripts/resolve-project.sh
  assert_file_exists ws/.behavior-kit/scripts/ensure-spec-dir.sh
  assert_file_exists ws/.behavior-kit/scripts/add-group-worktree.sh
  assert_file_exists ws/.behavior-kit/memory/constitution.md
  assert_file_exists ws/ROSTER-BOOTSTRAP-PROMPT.md
  # Per-repo-only artifacts must NOT come along.
  assert_file_missing ws/.behavior-kit/scripts/init-feature.sh
  assert_dir_missing ws/.cursor
  assert_executable ws/.behavior-kit/scripts/resolve-project.sh
}

test_headless_creates_specs_and_worktrees() {
  mkdir -p ws
  capture bash "$INSTALL_SH" --headless ws
  assert_rc_zero
  assert_dir_exists ws/specs
  assert_dir_exists ws/worktrees
}

test_headless_rejects_local() {
  mkdir -p ws
  capture bash "$INSTALL_SH" --headless ws --local
  assert_rc_nonzero
  assert_stderr_contains "can't be used together"
}

test_headless_rejects_init() {
  capture bash "$INSTALL_SH" --headless --init demo
  assert_rc_nonzero
  assert_stderr_contains "can't be used together"
}

# A bare root argument in per-repo mode is a typo, not a silent no-op.
test_headless_root_argument_requires_headless() {
  init_git_repo
  capture bash "$INSTALL_SH" some/root
  assert_rc_nonzero
}

test_headless_missing_root_fails() {
  capture bash "$INSTALL_SH" --headless does-not-exist
  assert_rc_nonzero
  assert_stderr_contains "does not exist"
}

# The constitution carries the Project registry, so a re-install must never
# clobber it — and anything else it changes must be recoverable.
test_headless_preserves_constitution_and_backs_up_changes() {
  mkdir -p ws
  capture bash "$INSTALL_SH" --headless ws
  assert_rc_zero

  echo "Project: myapp | repo=$PWD/repo | specs=$PWD/ws/specs/myapp | worktrees=$PWD/ws/worktrees/myapp" > ws/.behavior-kit/memory/constitution.md
  echo "Ratified: 2026-08-18" >> ws/.behavior-kit/memory/constitution.md
  echo "LOCAL EDIT" >> ws/.claude/commands/bk.quarterback.md

  capture bash "$INSTALL_SH" --headless ws
  assert_rc_zero
  assert_grep "Project: myapp" ws/.behavior-kit/memory/constitution.md
  assert_grep "LOCAL EDIT" ws/.claude/commands/bk.quarterback.md.bak-1
  if grep -q "LOCAL EDIT" ws/.claude/commands/bk.quarterback.md; then
    _fail "expected bk.quarterback.md to be refreshed from the scaffold"
  fi
}

# End to end: a registry entry resolves, and the phase gate accepts it.
test_headless_scripts_resolve_a_registered_project() {
  mkdir -p ws repo
  capture bash "$INSTALL_SH" --headless ws
  assert_rc_zero
  ( cd repo && init_git_repo && git commit --quiet --allow-empty -m seed )

  cat > ws/.behavior-kit/memory/constitution.md <<EOF
# Test Constitution
Project: myapp | repo=$PWD/repo | specs=$PWD/ws/specs/myapp | worktrees=$PWD/ws/worktrees/myapp
Ratified: 2026-08-18
EOF

  cd ws
  capture .behavior-kit/scripts/resolve-project.sh myapp
  assert_rc_zero
  [[ "$ASSERT_STDOUT" == *"/repo"* ]] || _fail "resolve-project did not print the repo path" "stdout: $ASSERT_STDOUT"

  capture .behavior-kit/scripts/check-prereqs.sh quarterback myapp
  assert_rc_zero

  capture .behavior-kit/scripts/resolve-project.sh nope
  assert_rc_nonzero
  assert_stderr_contains "unknown project"

  capture .behavior-kit/scripts/ensure-spec-dir.sh myapp PROJ-123
  assert_rc_zero
  assert_dir_exists "specs/myapp/PROJ-123"

  capture .behavior-kit/scripts/ensure-spec-dir.sh myapp not-a-key
  assert_rc_nonzero

  capture .behavior-kit/scripts/add-group-worktree.sh myapp PROJ-123 api feat
  assert_rc_zero
  assert_dir_exists "worktrees/myapp/PROJ-123-api"
  cd ..
}

# The git-repo guard must still fire for the default mode.
test_per_repo_install_still_needs_a_git_repo() {
  capture bash "$INSTALL_SH"
  assert_rc_nonzero
  assert_stderr_contains "not a git repository"
}

# The quarterback is mode-aware and lives in scaffold/ only. Two copies would
# drift apart silently, which is exactly what this layout exists to prevent.
test_quarterback_is_not_duplicated_across_trees() {
  assert_file_exists "$SCAFFOLD_DIR/.claude/commands/bk.quarterback.md"
  assert_file_missing "$REPO_ROOT/scaffold-headless/.claude/commands/bk.quarterback.md"
  # It must carry the mode switch, since both installs share this one copy.
  assert_grep "Detect your mode" "$SCAFFOLD_DIR/.claude/commands/bk.quarterback.md"
  assert_grep "grep -q .\\^Project:" "$SCAFFOLD_DIR/.claude/commands/bk.quarterback.md"
}
