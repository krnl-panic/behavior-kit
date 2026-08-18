---
description: "Watch a ticket's open PRs and address review feedback automatically, on a CI-paced loop"
---

# /bk.monitor — Watch PRs & Address Review Feedback

You monitor every open PR for a ticket and address new review feedback and CI failures automatically, re-checking on a self-paced loop whose interval is the repo's **average CI run time**. You pause for the user only on conflicting or ambiguous feedback. A spec implemented as parallel groups has **one PR per group**, so you may be tracking several PRs at once. The user provides the **project** (a name from the constitution's Project registry) and the Jira ticket key as $ARGUMENTS — e.g. `/bk.monitor myapp PROJ-123`.

## Gate

1. Parse the **project** and **ticket key** from $ARGUMENTS. If the project is missing or unknown, ask the user which project before continuing.
2. Run `.behavior-kit/scripts/check-prereqs.sh monitor <project>`. If it fails, stop and relay its error message to the user.
3. Confirm `gh` is installed and authenticated (`gh auth status`). If not, stop with: "Install and authenticate the GitHub CLI: https://cli.github.com".

## Setup (once per run)

1. Read the constitution; resolve the spec via `.behavior-kit/scripts/ensure-spec-dir.sh <project> <TICKET>` — its last line is `<SPEC_DIR>` (a plain directory). Read `<SPEC_DIR>/spec.md` and `behaviors.md` for context. Resolve the **project repo** (the `repo=` path in the registry) — run all `git`/`gh` commands against it (`git -C <repo> …`, or `gh … -R <owner>/<repo>` using the repo's origin).
2. **Discover the tracked PRs.** List every open PR whose head branch belongs to this ticket:
   ```bash
   gh pr list -R <owner>/<repo> --state open --json number,headRefName,title \
     --jq '[.[] | select(.headRefName | test("^(feat|fix|dev)/<TICKET>(-|$)"))]'
   ```
   If none are open, stop with: "No open PRs found for <TICKET>. Push the group branches and open PRs first (/bk.implement does this)."
3. **Compute the debounce interval = average CI run time.** Average the duration of recent completed runs across the tracked branches:
   ```bash
   gh run list -R <owner>/<repo> --branch <branch> -L 20 \
     --json status,conclusion,createdAt,updatedAt \
     --jq '[.[] | select(.status=="completed") | ((.updatedAt|fromdate)-(.createdAt|fromdate))] | add/length'
   ```
   Use the mean across the tracked branches. If there's no run history, default to **300** seconds. Clamp the result to **[60, 3600]** seconds.

## Each pass (per tracked PR)

1. **Pull Jira context** via the Atlassian MCP (`getJiraIssue <TICKET>`) — read ticket comments / linked discussion that bear on the feedback. If the MCP isn't connected, note it and continue.
2. Fetch feedback and CI status:
   - Inline review comments: `gh api repos/{owner}/{repo}/pulls/{pr}/comments`
   - PR-level comments: `gh pr view {pr} -R <owner>/<repo> --json comments --jq '.comments'`
   - Review summaries: `gh api repos/{owner}/{repo}/pulls/{pr}/reviews`
   - CI: `gh pr checks {pr} -R <owner>/<repo>`
3. Read `<SPEC_DIR>/review.md` if it exists — skip items already addressed (tracked per PR/round).
4. Categorize each new comment: **actionable** (code change), **question** (reply only), **acknowledgment** (note only).
5. For each **actionable** comment (and any failing CI):
   a. Make the change in the PR's worktree — test-first if it introduces new behavior; keep all tests passing.
   b. Reply on GitHub and resolve the thread:
      ```bash
      gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies -f body="Addressed in <type>(<TICKET>): [description]"
      gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "{threadId}"}) { thread { isResolved } } }'
      ```
   c. Commit cohesively (`<type>(<TICKET>): [description]`) and push.
6. For each **question**: reply with an explanation on GitHub; record in review.md.
7. **Force a turn with the user** on conflicting feedback (two reviewers disagree) or any comment whose intent is ambiguous — quote it and ask which direction to take. Do not guess.
8. Update `<SPEC_DIR>/review.md` (per-PR, per-round) from `.behavior-kit/templates/review-template.md`. It is a plain file — just write it (no commit, no push, no branch).

## Loop & self-pacing

After a pass over all tracked PRs, **re-arm** if any tracked PR is still open and unmerged: schedule the next pass in *(avg CI time)* seconds.
- Use `ScheduleWakeup` with `delaySeconds` = the computed interval (or run as `/loop /bk.monitor` and let the harness pace it).

**End the loop** when every tracked PR is merged, closed, or approved with no open threads. Report a final summary.

## Rules
- Cohesive commits per addressed item or closely-related cluster; tests stay green after every change.
- Reply to every actionable and question comment on GitHub; resolve threads only after actually addressing them.
- Never argue with feedback — address it, or force a turn for guidance.
- Pause (don't auto-decide) on conflicting or ambiguous feedback.
- If feedback would break existing behaviors, follow TDD: update the test first, then the code.

## Forbidden
- Auto-resolving conflicting/ambiguous feedback without the user
- Ignoring or skipping comments; force-pushing
- Resolving threads without addressing the feedback
- Weakening or removing tests to satisfy feedback

## Output
Each tracked PR's new feedback addressed (or escalated), threads replied to and resolved, an up-to-date per-PR `<SPEC_DIR>/review.md` (a plain file), and a loop that re-arms at the average CI interval until the PRs are done.
