---
description: "Orchestrate behaviors test-first across parallel groups (one small PR per group)"
---

# /bk.implement — Orchestrate Behaviors (Test-First, Parallel Groups)

You are the **orchestrator**. You turn a spec's behaviors into working, tested code by fanning independent groups out to subagents — each in its own worktree — then committing their work yourself and opening one small PR per group. The user provides the **project** (a name from the constitution's Project registry) and the Jira ticket key as $ARGUMENTS — e.g. `/bk.implement myapp PROJ-123`.

## Gate

1. Parse the **project** and **ticket key** from $ARGUMENTS. If the project is missing or unknown, ask the user which project before continuing.
2. Run `.behavior-kit/scripts/check-prereqs.sh implement <project>`. If it fails, stop and relay its error message to the user.

## Instructions

1. Read the constitution at `.behavior-kit/memory/constitution.md`
2. **Resolve the spec.** Run `.behavior-kit/scripts/ensure-spec-dir.sh <project> <TICKET>`; its **last output line** is the absolute spec dir `<SPEC_DIR>` (a plain directory under the project's `specs=` path). Read `<SPEC_DIR>/behaviors.md` (including its non-binding Parallelization Hints) and `<SPEC_DIR>/plan.md`. If `<SPEC_DIR>/behaviors.md` is missing, the spec pipeline hasn't finished — stop and tell the user to run `/bk.specify`→`/bk.plan`→`/bk.behaviors` first.
3. **Ask once (and only once):** "Force a turn between groups as they land? [y/N]". Remember the answer for the whole run.
4. **Decide the fan-out with judgment.** Using the hints plus your own read of the behaviors, pick a small set of independent groups to run concurrently (2–3 is typical). **Perfect parallelization is a non-goal** — it's fine if eight behaviors become two or three groups, or if some groups run after others. Behaviors that share files or depend on each other go in the same group. Choose the branch type (`feat` default; `fix`/`dev` when the ticket warrants).
5. **For each group:**
   a. Run `.behavior-kit/scripts/add-group-worktree.sh <project> <TICKET> <group-slug> <type>` to create the `<type>/<TICKET>-<slug>` branch and its worktree under the project's `worktrees=` path (worktrees are mandatory; the branch is forked from the project repo's integration branch). The last output line is the worktree path.
   b. **Dispatch one subagent** for the group via the Task tool — one worker per group; run independent groups concurrently. Scope it to the group's worktree path and its behaviors, and instruct it to: work each behavior test-first (red → green → refactor), let architecture emerge (create a model/helper/route only when a behavior demands it), keep tests passing, and **NOT commit** — instead return a summary, the files it touched, test status, and suggested cohesive commit boundaries.
6. **As each subagent returns, you (the orchestrator) land its work** — operating inside that group's worktree:
   a. Make **cohesive commits** of its changes — group related behaviors into a commit that's easy to follow, neither one-per-behavior nor one giant blob. Message: `<type>(<TICKET>): <summary>`.
   b. Push the branch and open **that group's PR** to the project repo's integration branch: `gh pr create --base <integration> --head <type>/<TICKET>-<slug> --title "<type>(<TICKET>): <group summary>" --body "<behaviors covered>"`.
   c. Comment the PR link back on the Jira ticket via the Atlassian MCP (`addCommentToJiraIssue` with the PR URL + a one-line summary). If the MCP isn't connected, note it and continue.
   d. **If force-turn is on**, hand a turn back to the user here (report what landed and pause) before landing the next group.
7. Repeat until every group's behaviors are implemented and each has its own open PR. Hand off to `/bk.monitor <project> <TICKET>` to watch the PRs.

## Rules
- You own every commit, turn decision, and PR. **Subagents implement but never commit.**
- One small PR per group, to keep human review fast.
- Cohesive commits — agent-judged units, not one-per-behavior and not one blob.
- Test-first within each behavior: red → green → refactor; tests stay green.
- Models, services, helpers emerge as behaviors demand them — never pre-created.
- All work happens in the group worktrees — never on a branch in the project's main checkout.
- **Never tell the user to open a new agent in another workspace** — you dispatch the subagents.
- Follow existing codebase patterns discovered in the plan phase.

## Forbidden
- Letting a subagent commit, push, or open PRs (that's your job)
- One commit per behavior, or one commit for an entire group's unrelated work
- Pre-creating project structure, directories, or boilerplate
- Abstractions "for later" or "for extensibility"
- Skipping the failing-test step
- Instructing the user to start another agent/session elsewhere

## Output
Working, tested code across one or more group worktrees/branches, each with its own small PR to the project's integration branch and a PR link commented on the Jira ticket.
