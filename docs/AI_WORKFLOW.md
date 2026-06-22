# ReplyWise AI Workflow

Source of truth: `docs/ReplyWise_development_plan.md`

These files are working summaries. Read the full plan when starting a phase, resolving ambiguity or conflict, or changing architecture, API contracts, security, billing, privacy, or release behavior.

## Roles

- ChatGPT: planning, architecture discussion, prompt design, trade-off analysis, and decision review.
- Claude Code: implementation within the current phase, tests, and blocking review fixes.
- Codex: evidence-based review, test verification, bug finding, and blocking/non-blocking classification.

## Development loop

1. Read `AI_CONTEXT.md` and the current phase checklist.
2. Claude Code implements only the current phase scope.
3. Run the phase checklist tests.
4. Codex reviews against the same checklist.
5. Claude Code fixes blocking issues only and reruns tests.
6. Commit a focused, passing change.
7. Push the reviewed branch.

Do not read the full plan for routine work when the context and checklist are clear. Do not implement future-phase features early. Blocking issues must be fixed before commit; non-blocking suggestions may be deferred.

## Issue classification

- Blocking: violates the current phase contract, breaks required behavior, tests, security, billing correctness, data integrity, or build/release viability.
- Non-blocking: maintainability, naming, test-depth, UX refinement, or optimization that does not prevent current phase acceptance.

## Claude implementation prompt

```text
Read docs/AI_CONTEXT.md and docs/PHASE_<N>_CHECKLIST.md.
Implement only the allowed scope for Phase <N>.
Treat docs/ReplyWise_development_plan.md as source of truth if the checklist is unclear.
Do not implement future phases or unrelated cleanup.
Preserve existing user changes. Run all tests listed in the checklist.
Return changed files, test results, and any blockers.
```

## Codex review prompt

```text
Review the current implementation only against docs/AI_CONTEXT.md and
docs/PHASE_<N>_CHECKLIST.md. Use docs/ReplyWise_development_plan.md only
to resolve ambiguity. Do not implement fixes.
Return PASS or NEEDS CHANGES, blocking issues, non-blocking issues,
exact files to change, and test evidence.
```

## Claude blocking-fix prompt

```text
Fix only the blocking issues from the Phase <N> Codex review.
Do not address deferred suggestions or add features.
Rerun the checklist tests and report exact files changed and results.
```

## Commit and push checklist

- Review `git diff` and confirm only intended phase files changed.
- Confirm generated files are synchronized where the project tracks them.
- Run `flutter analyze` and `flutter test` for Flutter changes.
- Run `python -m pytest` (or the platform-equivalent Python launcher) for backend changes.
- Confirm no blocking review issues remain.
- Use a focused commit message describing one phase outcome.
- Push the reviewed branch; do not force-push unless explicitly authorized.

## Never commit

- `.env` files, model-provider keys, JWT secrets, server pepper, RevenueCat secret keys, or production credentials.
- Build output, local caches, Python `__pycache__`, editor state, test artifacts, or local database data.
- User message bodies, prompt samples containing private data, signing keystores, or service-account credentials.

