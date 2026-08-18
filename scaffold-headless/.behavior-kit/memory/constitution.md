# Project Constitution

## Article I — Test-Driven Development (NON-NEGOTIABLE)
Every unit of work is a testable behavior: action + input → expected output. Write the test first, confirm it fails, implement the minimum to pass, refactor. No code without a failing test.

## Article II — Epistemic Humility (NON-NEGOTIABLE)
Trust tools over intuition. Run the test, read the error, check the output. Never assume code works — verify it. When uncertain, investigate before acting.

## Article III — Code Is a Liability
Every line of code is a line to maintain, debug, and understand. Less code means fewer bugs, faster onboarding, and easier change. Delete aggressively. Resist adding. The best code is the code you never wrote.

## Article IV — Lean Specification
Specs use Given/When/Then acceptance criteria. They describe WHAT and WHY, never HOW. No data models, no API shapes, no technology choices in specs.

## Article V — Organic Architecture
YAGNI, DRY, SRP. Models, services, and helpers emerge from behavior needs, never pre-planned. Three similar lines are better than a premature abstraction.

## Article VI — No Skips, No Ignores, No Bypasses (NON-NEGOTIABLE)
No skipped tests, no disabled linters, no type ignores, no `--no-verify`. If a check fails, fix the root cause. Quality gates exist for a reason.

## Article VII — Progressive Context
Each phase loads only what it needs. Specify loads the constitution. Plan loads the spec + codebase. Behaviors loads the plan. Implement loads one behavior at a time.

## Article VIII — Self-Documenting Code
Code should be readable without comments. Use clear names, small functions, and obvious structure. Add comments only where the WHY isn't self-evident. DocC/JSDoc for public APIs only.

## Article IX — Conventional Commits & Jira Traceability
Every branch is scoped to a Jira ticket: `<type>/<JIRA-KEY>` for a single-group spec, or `<type>/<JIRA-KEY>-<group>` for one of a spec's parallel behavior groups (e.g. `feat/PROJ-123-api`), where type is `feat`/`fix`/`dev`. Group branches are created at implement time, not before. Sessions use the broader conventional-commit tag set. Commits are cohesive units of work — not one-per-behavior and not one giant blob — and their messages, PR titles, and squash-merge subjects follow Conventional Commits scoped to the ticket: `type(PROJ-123): summary`. Every change traces branch → ticket → commit.

## Article X — Trunk, Merge & Review Discipline
Feature work never lands directly on an integration branch (`main`, `stage`, `master`, `develop`); it ships through a reviewed PR. Each parallel behavior group opens its own small PR so reviews stay fast and land independently. PRs squash-merge into the integration branch with a Conventional-Commit title; merges to `main` are fast-forward or 3-way. A PR is mergeable only when the pipeline/tests are green, the linter is clean (no `--no-verify`, per Article VI), the acceptance criteria are met, and the diff stays scoped to its ticket.

---

_This workspace runs behavior-kit **centrally** from `$HOME/dev`: one kit (`.behavior-kit/` + `.claude/commands/bk.*`) serves every project in the registry below. Specs are **plain directories** under each project's `specs=` path (`<specs>/<TICKET>/`) — no git, no branch, no push; `spec.md`/`plan.md`/`behaviors.md`/`review.md` are working notes written straight to disk. Every repo-touching phase **always** operates inside a **git worktree** created under the project's `worktrees=` path and forked from the project repo's integration branch — behavior-kit never works on a branch in a project's main checkout (which stays on its integration branch). Jira is read/written through the Atlassian MCP. Each phase takes the **project name** as its leading argument; scripts resolve the project's paths from the registry. `/bk.constitution` records one `Project:` line per project plus the ratified date:_

```
Project: <name> | repo=~/dev/<repo-dir> | specs=~/dev/specs/<name> | worktrees=~/dev/worktrees/<name>
Ratified: YYYY-MM-DD
```

_Add project-specific articles below (Article XI+):_
