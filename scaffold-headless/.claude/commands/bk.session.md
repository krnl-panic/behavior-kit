---
description: "Start a lightweight pairing session — branch + worktree, no spec/plan/behaviors workflow"
---

# /bk.session — Pairing / One-off Session

You are starting a lightweight, interactive session with the user — a one-off fix, a refactor pass, a QA round, anything that doesn't warrant the full spec → plan → behaviors → implement pipeline. The user provides the **project** (a name from the constitution's Project registry) and, optionally, the session's purpose as $ARGUMENTS — e.g. `/bk.session web fix the join-link 404`.

## Gate

1. Parse the **project** (first token: a name from the constitution's Project registry) from $ARGUMENTS. If it's missing or unknown, ask the user which project before continuing. Treat the rest of $ARGUMENTS as the purpose.
2. Run `.behavior-kit/scripts/check-prereqs.sh session <project>`. If it fails, stop and relay its error message to the user.

## Instructions

1. Read the constitution at `.behavior-kit/memory/constitution.md` — it governs this session the same way it governs spec work.
2. **Establish the purpose.** If a purpose came in $ARGUMENTS, use it. Otherwise ask the user one inline question: *"What's this session for? (one or two sentences is fine — a bug to fix, a refactor to try, a UI tweak to QA, etc.)"* Wait for their answer.
3. **Pick a conventional-commit tag** that best matches the purpose. Choose from: `fix`, `dev`, `chore`, `refactor`, `docs`, `test`, `ci`, `build`, `perf`, `style`, `revert`. Do not use `feat` — that's `/bk.specify`'s domain. If the purpose genuinely sounds like a new feature, stop and suggest `/bk.specify` instead.
4. **Derive a short slug** — 3-5 kebab-case words summarizing the purpose (e.g. `login-redirect-loop`, `bump-node-22`, `extract-auth-helper`).
5. Run `.behavior-kit/scripts/init-session.sh <project> <tag> "<slug>"`. Worktrees are mandatory: the script creates the `{tag}/{slug}` branch and a matching worktree under the project's `worktrees=` path, forked from the project repo's integration branch. Its last line is the worktree path to operate in.
6. **Enter the worktree** (`EnterWorktree path=<worktree>`) before continuing. All work for this session lives there.
7. From that point on, **pair with the user freely**. There is no behaviors.md, no test-first ceremony, no commit-per-behavior. Use your normal judgment for tests, commits, and scope — but the constitution still applies (Article I TDD where it makes sense, Article II epistemic humility always, etc.).

## Rules
- One purpose per session. If the conversation drifts to unrelated work, suggest ending this session and starting another.
- The branch name carries the intent — make the tag and slug accurate, since they'll show up in `git log` and any PR you open later.
- Sessions never enter the spec workflow — they produce no spec, plan, behaviors, or PR-monitoring artifacts. If a one-off grows into ticketed work, end the session and start a real spec with `/bk.specify`.

## Forbidden
- Using the `feat` tag (route real features through `/bk.specify`).
- Writing a `specs/<TICKET>/` or `sessions/…/` markdown artifact — sessions are deliberately ephemeral.
- Working on a branch in the project's main checkout — sessions always get their own worktree.
- Running other `/bk.*` phases on the session branch.

## Output
A `{tag}/{slug}` branch and matching worktree under the project's worktrees path, ready for interactive pairing.
