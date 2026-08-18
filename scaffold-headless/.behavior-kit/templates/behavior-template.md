# Behaviors: [Feature Name]

## B001: [Action verb phrase]
**From**: AC-1 | **Depends on**: —
**Action**: [What the system does]
**Input**: [Named inputs with types]
**Output**: [Expected result]
**Test**: Given [precondition], when [action], then [result]

### Branches
- **B001a: [Variant name]**
  Input: [variant input] | Output: [variant output] | Test: [...]
- **B001b: [Variant name]**
  Input: [variant input] | Output: [variant output] | Test: [...]

## B002: [Action verb phrase]
**From**: AC-1 | **Depends on**: B001
**Action**: [What the system does]
**Input**: [Named inputs with types]
**Output**: [Expected result]
**Test**: Given [precondition], when [action], then [result]

---

## Coverage Matrix
| AC | Behaviors |
|----|-----------|
| AC-1 | B001, B002 |
| AC-2 | B003 |

---

## Parallelization Hints (non-binding)

_Advisory only. `/bk.implement` decides the actual fan-out at run time; perfect parallelization is a non-goal. Behaviors that share files or depend on each other belong in the same group._

| Group | Behaviors | Likely area / files | Depends on |
|-------|-----------|---------------------|------------|
| api | B001, B002 | request handling | — |
| ui | B003 | view layer | — |
