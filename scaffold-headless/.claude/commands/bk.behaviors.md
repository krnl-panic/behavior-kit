---
description: "Decompose acceptance criteria into atomic, testable behaviors with parallelization hints"
---

# /bk.behaviors — The HOW (as Testable Behaviors)

You are decomposing a feature spec into atomic, testable behaviors. The user provides the **project** (a name from the constitution's Project registry) and the Jira ticket key as $ARGUMENTS — e.g. `/bk.behaviors myapp PROJ-123`.

## Gate

1. Parse the **project** and **ticket key** from $ARGUMENTS. If the project is missing or unknown, ask the user which project before continuing.
2. Run `.behavior-kit/scripts/check-prereqs.sh behaviors <project>`. If it fails, stop and relay its error message to the user.

## Instructions

1. Read the constitution at `.behavior-kit/memory/constitution.md`
2. **Resolve the spec location.** Run `.behavior-kit/scripts/ensure-spec-dir.sh <project> <TICKET>`; it prints the absolute spec dir `<SPEC_DIR>` as its **last line**. Specs are plain files — no git.
3. Read the spec at `<SPEC_DIR>/spec.md` and the plan at `<SPEC_DIR>/plan.md`
4. Read the behavior template at `.behavior-kit/templates/behavior-template.md`
5. For each acceptance criterion, decompose into atomic behaviors:
   - Each behavior: Action + Input + Output + Test mapping
   - Add branches for error cases, empty states, edge cases
   - Order by dependency (not by layer)
6. Build a coverage matrix: every AC must map to at least one behavior
7. **Add Parallelization Hints (non-binding).** Cluster behaviors that have no cross-dependencies into candidate groups, each with a short name and a one-line note on the likely file/area it touches. These are *hints only*: `/bk.implement` decides the actual fan-out at run time with its own judgment, and **forced or perfect parallelization is a non-goal** — a spec with eight behaviors might run as two or three groups, or one. Behaviors that share files or depend on each other belong in the same group.
8. Write to `<SPEC_DIR>/behaviors.md` (a plain file — no commit, no push). Once spec.md, plan.md, and behaviors.md all exist in `<SPEC_DIR>`, the spec is complete — `/bk.implement <project> <TICKET>` reads them straight from that directory.

## Behavior Format

```markdown
## B001: [Action verb phrase]
**From**: AC-1 | **Depends on**: —
**Action**: [What the system does]
**Input**: [Named inputs with types]
**Output**: [Expected result]
**Test**: Given [precondition], when [action], then [result]

### Branches
- **B001a: [Variant name]**
  Input: [variant input] | Output: [variant output] | Test: [...]
```

## Rules
- B-numbers (B001, B002...), not T-numbers
- Branches are first-class (B001a, B001b...)
- Every behavior has a "From" tracing back to an AC
- Every AC must be covered in the coverage matrix
- Order by dependency, not by implementation layer
- Parallelization hints are advisory; never force a behavior into a group just to maximize concurrency

## Forbidden
- Organizing the behaviors themselves by layer (models → services → controllers)
- Specifying file paths or module names within a behavior
- "Setup" or "scaffolding" tasks
- Implementation hints or technology choices
- Phase grouping (Phase 1, Phase 2...) — parallelization groups are about independence, not sequence

## Output
`<SPEC_DIR>/behaviors.md` — a plain file under the project's specs path.
