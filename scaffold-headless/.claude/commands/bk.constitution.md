---
description: "Create or update project constitution with behavior-first principles"
---

# /bk.constitution — Project Principles

You are setting up or updating the project constitution for this **centralized, multi-project** behavior kit. One kit at the workspace root serves every project in the registry; specs are plain directories and worktrees are mandatory.

## Instructions

1. **Project registry (REQUIRED — establish first).** Each project the kit serves is one line in the constitution:

   ```
   Project: <name> | repo=<abs-repo-path> | specs=<abs-specs-path> | worktrees=<abs-worktrees-path>
   ```

   - `<name>` is the short handle callers pass as the leading argument to every phase (e.g. `myapp`, `web`).
   - `repo=` is the local git clone of the project's repository.
   - `specs=` is where this project's specs live as **plain directories** (`<specs>/<TICKET>/`) — no git, no branch, no push.
   - `worktrees=` is where this project's **worktrees** are created (worktrees are mandatory; every repo-touching phase forks a worktree here from the repo's integration branch — the kit never works on a branch in the repo's main checkout).

   Check what's already recorded (`grep -E '^Project:' .behavior-kit/memory/constitution.md || true`). For a new project, ask the user for its repo path and confirm the `specs=`/`worktrees=` paths (default to `<workspace>/specs/<name>` and `<workspace>/worktrees/<name>`), then add its line. After editing the registry, run `.behavior-kit/scripts/setup-worktrees.sh` to create the worktrees directories.

2. **Atlassian MCP (REQUIRED dependency — confirm, don't store).** behavior-kit reads and writes Jira through the Atlassian MCP: `/bk.specify` seeds the spec from the ticket, `/bk.implement` comments the PR link back, `/bk.monitor` pulls review context. Confirm the MCP is connected (e.g. the `atlassianUserInfo` tool resolves). If it is not, tell the user the kit's Jira steps will fail until they connect the Atlassian MCP, and let them decide whether to proceed.

3. Read the current constitution at `.behavior-kit/memory/constitution.md`
4. If this is a new setup, present Articles I-X (the defaults) and explain each briefly
5. Ask the user (max 3 questions inline) what project-specific principles to add as Articles XI+
6. Update the constitution file with any new articles
7. Keep the decision lines together (one `Project:` line per project) and add or update the ratified line beneath them: `Ratified: YYYY-MM-DD`

## Rules
- At least one `Project:` line plus the `Ratified:` line must be recorded before any other phase will run (`check-prereqs.sh` enforces both). Never skip step 1.
- Articles I-X are foundational — they can be amended but not removed
- Project-specific articles go in the XI+ section
- Keep articles concise: one principle per article, 2-3 sentences max
- The constitution is referenced by all other phases — keep it authoritative

## Output
Updated `.behavior-kit/memory/constitution.md` with one `Project:` line per project and a `Ratified:` line, and the per-project worktrees directories created.
