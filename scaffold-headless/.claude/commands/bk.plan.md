---
description: "Research existing codebase and current implementation context for a feature spec"
---

# /bk.plan — The CONTEXT (Research + Recommendations Only)

You are researching the codebase and the current implementation landscape to provide context for implementing a feature. The user provides the **project** (a name from the constitution's Project registry) and the Jira ticket key as $ARGUMENTS — e.g. `/bk.plan myapp PROJ-123`.

## Gate

1. Parse the **project** and **ticket key** from $ARGUMENTS. If the project is missing or unknown, ask the user which project before continuing.
2. Run `.behavior-kit/scripts/check-prereqs.sh plan <project>`. If it fails, stop and relay its error message to the user.

## Instructions

1. Read the constitution at `.behavior-kit/memory/constitution.md`
2. **Resolve the spec location.** Run `.behavior-kit/scripts/ensure-spec-dir.sh <project> <TICKET>`; it prints the absolute spec dir `<SPEC_DIR>` as its **last line**. Read the spec at `<SPEC_DIR>/spec.md`. Specs are plain files — no git.
3. **Dependency / duplication gate (REQUIRED — before any codebase research).** Enumerate every other in-flight spec for this project to make sure this one isn't duplicating effort or silently depending on work that hasn't landed yet:
   - List sibling spec dirs under the project's `specs=` path (the directories next to `<SPEC_DIR>`) and inspect the union of their `spec.md`, `plan.md`, and `behaviors.md` (some won't exist yet — fine).
   - Also enumerate active worktrees for the project: `git -C <project-repo> worktree list` (the project repo is the `repo=` path in the constitution registry) so you can see which specs/sessions are being implemented right now.
   - For each sibling, decide whether the current spec **(a) overlaps in scope** (would re-implement the same behavior, file, screen, or model), **(b) depends on an unmerged artifact** (needs a type, component, repository, migration, route, or test helper that another in-flight spec is introducing), or **(c) is independent**.
   - If you find any (a) or (b) match, **STOP and force a turn with the user** via `AskUserQuestion`. Quote the sibling spec ID and the specific overlap/dependency, and offer the obvious choices (e.g. "wait for spec <TICKET> to merge", "absorb spec <TICKET>'s work", "narrow this spec to exclude X", "proceed anyway — overlap is intentional"). Do not proceed to step 4 until the user answers.
   - Record the decision in the plan's "Dependencies / coordination" section so the next phase can see it; for every sibling spec considered, note the verdict (independent / overlaps / depends-on) so a reviewer can audit the check.
4. Read the plan template at `.behavior-kit/templates/plan-template.md`
5. Explore the existing codebase thoroughly:
   - Identify patterns and conventions already in use
   - Find code that the feature will interact with
   - Note external dependencies or contracts
6. Perform focused live web research for the feature's likely implementation surface:
   - Use current-year sources where possible, prioritizing official docs, standards, release notes, and reputable project guidance
   - Capture implementation trends, best practices, and cautions relevant to this feature
   - Prefer primary sources for APIs, frameworks, libraries, security, accessibility, deployment, or platform constraints
   - If live web access is unavailable, state that clearly and do not invent current guidance
7. Write the plan to `<SPEC_DIR>/plan.md` (a plain file — no commit, no push).

## Rules
- Document existing patterns and give them real weight, but do not treat them as the only acceptable path
- Reference snippets come from EXISTING code only
- Offer better-way recommendations when current practice, live research, or the spec suggests a more adaptable approach
- Label web findings as recommendations, tradeoffs, or cautions — never decisions
- Compare recommendations against the existing codebase, constitution, and spec before presenting them
- Favor the smallest change that achieves the desired behavior; code is a liability, so every recommended addition needs a reason
- Keep recommendations scoped to the feature; if a recommendation expands scope, call that out as a tradeoff and ask the user before carrying it forward
- Open questions must include a proposed answer
- This is research and recommendation, not design

## Forbidden
- Inventing final data models, schemas, API contracts, endpoint shapes, project structures, or directories as decisions
- Writing new code or pseudocode
- Presenting architectural recommendations as settled implementation decisions
- Treating popularity, novelty, or "best practice" language as authority without local fit and testability

## Output
`<SPEC_DIR>/plan.md` — a plain file under the project's specs path.
