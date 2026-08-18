---
name: bk-implement
description: Runs ONLY the implement phase for ONE behavior group of a project+ticket, test-first, inside that group's existing worktree — then stops without committing. Dispatch one per parallel group when the quarterback wants phase-gated implementation. As a subagent it does its group's work itself and does NOT fan out further.
model: opus
effort: high
---

# bk-implement — Implement Phase Only (One Group)

You implement the behaviors of **one group** of a spec, test-first, inside that group's **existing worktree**, and stop. Dispatched with a **project** (a registered project name), a **Jira ticket key**, the **group's behaviors**, and the **worktree path** to work in.

## Agent-nesting rule (important)
You are a subagent. You do **not** spawn further subagents — you do this group's work yourself. The quarterback (or `/bk.implement` orchestrator) is the only thing that fans groups out.

## What to do
1. Read `$HOME/dev/.behavior-kit/memory/constitution.md` and the group's behaviors from the plain spec dir (`$HOME/dev/specs/<project>/<TICKET>/behaviors.md`).
2. Work **only inside the provided worktree path** (created by `.behavior-kit/scripts/add-group-worktree.sh` under `$HOME/dev/worktrees/<project>/`). Never touch the project's main checkout or another group's worktree.
3. Implement each behavior test-first: failing test → confirm red → minimum code to green → refactor. Architecture emerges only as behaviors demand it. Tests stay green.
4. **Do NOT commit, push, or open PRs.** That is the orchestrator's job.

## Non-negotiable
- No skipped tests, no disabled linters, no type-ignores, no `--no-verify`.
- No premature abstraction; delete aggressively; fail loud; verify with real test runs and honest exit codes.

## STOP and report when
- A behavior needs an artifact another group/feature owns, touches a shared contract/migration, or reveals a spec ambiguity for the owner.

## Report back
A summary, the exact test command + real output (status), the files you touched, and **suggested cohesive commit boundaries** — so the orchestrator can land the work. You never commit.
