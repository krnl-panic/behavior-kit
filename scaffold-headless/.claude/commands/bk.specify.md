---
description: "Generate a behavior-first spec with Given/When/Then acceptance criteria, seeded from Jira"
---

# /bk.specify — The WHAT and WHY

You are writing a feature specification, seeded from its Jira ticket. The user provides the **project** (a name from the constitution's Project registry) and the Jira ticket key as $ARGUMENTS — e.g. `/bk.specify myapp PROJ-123`.

## Gate

1. Parse the **project** (first token: a name from the constitution's Project registry) and the **ticket key** from $ARGUMENTS. If the project is missing or unknown, ask the user which project before continuing.
2. Run `.behavior-kit/scripts/check-prereqs.sh specify <project>`. If it fails, stop and relay its error message to the user.

## Instructions

1. Read the constitution at `.behavior-kit/memory/constitution.md`
2. Confirm the Jira ticket key (e.g. `PROJ-123`) — ask the user if it isn't clear.
3. **Seed from Jira (REQUIRED).** Fetch the ticket through the Atlassian MCP — `getJiraIssue` with the key — and read its summary, description, and any acceptance criteria. Use them as the basis for the spec. If the Atlassian MCP is not connected (the call fails), stop with: "Atlassian MCP not connected — connect it (or re-run /bk.constitution) before specifying." Do not invent ticket content.
4. **Resolve the spec location.** Run `.behavior-kit/scripts/ensure-spec-dir.sh <project> <TICKET>`. Specs are **plain directories** under the project's `specs=` path; the script creates the directory and prints the absolute spec dir `<SPEC_DIR>` as its **last output line**. There is no git branch and no push — spec files are working notes written straight to disk.
5. Read the spec template at `.behavior-kit/templates/spec-template.md`
6. Ask the user up to 3 inline clarification questions if the ticket leaves gaps (do not stop to wait — batch them)
7. Write the spec to `<SPEC_DIR>/spec.md`

## Rules
- User story format: As a [role], I want to [action], So that [outcome]
- Every acceptance criterion uses Given/When/Then
- Include edge cases and out-of-scope sections
- Max 3 inline clarification questions — no separate clarify phase
- The spec is the source of truth even when it diverges from the ticket; note any divergence you introduced

## Forbidden
- Technology mentions (frameworks, languages, databases)
- Data models or schemas
- API shapes or endpoint definitions
- FR-tables or numbered requirement lists
- Implementation checklists
- Committing, branching, or pushing the spec (specs are plain files — never under git here)

## Output
`<SPEC_DIR>/spec.md` — a plain file under the project's specs path.
