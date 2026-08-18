---
description: "Advanced — fan a Jira epic into multiple specs and an implement orchestrator per child story"
---

# /bk.epic — Epic → Specs → Parallel Implement (Advanced)

You are taking a whole Jira **epic** from tickets to parallel PRs: enumerate its child stories, run the spec pipeline for each, then drive an `/bk.implement` orchestrator per story (each of which itself fans groups out to subagents). This is the high-octane mode — it can spawn a lot of work, so confirm scope with the user before launching. The user provides the **project** (a name from the constitution's Project registry) and the epic key as $ARGUMENTS — e.g. `/bk.epic myapp PROJ-1200`.

## Gate

1. Parse the **project** and **epic key** from $ARGUMENTS. If the project is missing or unknown, ask the user which project before continuing.
2. Run `.behavior-kit/scripts/check-prereqs.sh epic <project>`. If it fails, stop and relay its error message to the user. The Atlassian MCP must be connected (this skill reads Jira heavily).

## Instructions

1. Read the constitution at `.behavior-kit/memory/constitution.md`
2. **Enumerate the epic's children** via the Atlassian MCP `searchJiraIssuesUsingJql` — try `parent = <EPIC>` and, if the project uses classic epics, `"Epic Link" = <EPIC>`. List the child story keys + summaries.
3. **Confirm scope with the user.** Show the child stories you found and how many spec pipelines + implement orchestrators that implies. Let the user drop any children or cap concurrency before you proceed.
4. **Per child story, run the spec pipeline** (each step is the existing skill, seeded from Jira, all against the same `<project>`): `/bk.specify <project> <CHILD>` → `/bk.plan <project> <CHILD>` (its dependency gate compares the other children and forces a turn on overlap/ordering) → `/bk.behaviors <project> <CHILD>`. Each child's spec is a plain directory under the project's `specs=` path at `<specs>/<CHILD>/`; `/bk.implement` reads each child's spec straight from there.
5. **Implement.** For each child story whose dependencies are satisfied, run `/bk.implement <project> <CHILD>` — the orchestrator that creates the child's group worktrees and dispatches its own subagents, owning that story's commits and PRs.
6. Hand off to `/bk.monitor <project> <CHILD>` per story (or per epic) to watch the resulting PRs.

## Agent-nesting cap (read this)
Nesting **works** — a capability probe (2026-07-24) confirmed a subagent can dispatch subagents in this harness, so the old "orchestrators must run from the top level" rule was based on a limit that does not exist. What stands is a deliberate **cap**: `/bk.epic` → one implement orchestrator per story → that story's group agents, and the group agents do not fan out further. Each implement orchestrator is still the thing that parallelizes across its story's groups. Pace concurrency because you chose a wave size, not because the harness forces it: spec-pipeline the children (cheap, can interleave), then run the implementable children's orchestrators within the concurrency cap the user confirmed, respecting the ordering the plan phase's dependency gate surfaced.

## Rules
- Confirm scope before launching; never silently start dozens of agents.
- Reuse the existing skills (`specify`/`plan`/`behaviors`/`implement`/`monitor`) — don't reimplement them.
- Thread the same `<project>` through every child's pipeline.
- Honor cross-story dependencies discovered by the plan dependency gate; implement prerequisites first.
- One PR per group still holds — an epic just produces more of them.

## Forbidden
- Nesting subagents inside subagents (see the constraint above)
- Skipping the spec pipeline for a child "to save time"
- Implementing a child whose unmerged dependency hasn't landed

## Output
A spec (spec/plan/behaviors) as a plain directory under the project's specs path at `<specs>/<CHILD>/` for each child story, and per-story group PRs opened by the implement orchestrators; the whole epic moving in parallel.
