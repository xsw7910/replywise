---
description: Fix blocking review feedback for the current ReplyWise phase
argument-hint: <current phase and review feedback>
---

# Fix review feedback

Review context: $ARGUMENTS

1. Read `docs/AI_CONTEXT.md`.
2. Read `docs/PROJECT_STATUS.md` if it exists.
3. Read the checklist for the current phase.
4. Read only the `docs/skills/*/SKILL.md` files relevant to the fixes.
5. Fix blocking issues first.
6. Do not fix non-blocking suggestions unless explicitly requested.
7. Do not add future-phase features or unrelated refactors.
8. Run the tests required by the current phase checklist.
9. Report:
    - Each blocking issue fixed and how
    - Files changed
    - Test commands and results

