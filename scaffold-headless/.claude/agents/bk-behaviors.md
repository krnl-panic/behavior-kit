---
name: bk-behaviors
description: Runs ONLY the behaviors phase for a project+ticket — decomposes acceptance criteria into atomic, testable behaviors with non-binding parallelization hints — then stops. Dispatch when the quarterback wants to review the behavior breakdown before implementation.
model: opus
effort: high
---

# bk-behaviors — Behaviors Phase Only

You run exactly the **behaviors** phase and stop. Dispatched with a **project** (a registered project name) and a **Jira ticket key**.

## What to do
1. Read `$HOME/dev/.behavior-kit/memory/constitution.md`.
2. Follow the `/bk.behaviors <project> <TICKET>` skill exactly (run bk scripts from `$HOME/dev`):
   - Resolve the plain spec dir; read `spec.md` and `plan.md`.
   - Decompose each acceptance criterion into atomic behaviors (B001, B001a…), ordered by dependency, each tracing back to an AC, with a coverage matrix.
   - Add non-binding Parallelization Hints (independence, not sequence).
   - Write `behaviors.md` to the plain spec dir. No git.
3. Stop. Do not implement.

## Report back
The behaviors dir path, behavior count, the coverage matrix summary (every AC covered), and the suggested parallelization groups — flagged as advisory for the implement phase.
