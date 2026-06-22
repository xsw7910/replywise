# Phase 7 Checklist — Pre-launch Polish

Source of truth: `docs/ReplyWise_development_plan.md`

## Phase goal

Improve stability, feedback, observability, quality, performance, and review readiness before closed testing or production, without expanding product scope.

## Allowed scope

- Error copy, delayed/loading states, crash/error logging, generation copy-rate event, token/cost analytics, prompt quality evaluation/tuning, UI refinement, accessibility, and performance fixes.
- Final regression, privacy, billing, and store-review checks.

## Not allowed yet

- Large new features, email/social login, cloud history, custom cloud guidance library, floating bubble, keyboard extension, multiple themes, dark mode, automatic sending, or broader post-MVP work.

## Required Flutter work

- Every network/generation/purchase state has clear loading, retry, cancellation, offline, and actionable error UX.
- Long-running generation does not appear frozen; duplicate taps are safely controlled.
- Copy behavior is reliable and records the planned copy-rate event without message content.
- Polish the single light-blue glass UI for readability, contrast, layout, and consistent tokens; result cards remain near-opaque and readable.
- Limit active glass layers and avoid large scrolling blur costs; verify low-end Android behavior.
- Respect reduced transparency/motion where available and preserve a solid/less-blurred fallback.

## Required backend work

- Structured crash/error logging and operationally useful request metadata without storing message bodies or secrets.
- Record model, endpoint, tokens, success/error, source, prompt version, and cache-hit/cost inputs for analysis.
- Improve error mapping and delayed-model behavior without changing accounting semantics.
- Run prompt quality samples and tune only within existing Reply/Polish/Explain contracts; do not weaken natural-English quality for cost alone.

## Required files/folders

- Existing UI/network/controller/service/prompt/config files as needed for polish.
- Logging/analytics configuration and documented quality/regression evidence.
- Store/privacy documents only when actual wording or behavior needs alignment.

## Security/billing notes

- Analytics and logs contain no incoming, guidance, draft, polished, generated, token, credential, or purchase-secret content.
- Do not change free/premium/credit ordering, nullable premium semantics, idempotency, or verified purchase rules during polish without returning to the source plan.

## Acceptance criteria

- Main flows are stable across success, offline, timeout, malformed response, cancellation, expiry, and purchase/sync failures.
- UI is readable and responsive on representative low-end and standard Android devices.
- Logs and metrics support crash, cost, latency, model, prompt-version, and copy-rate diagnosis without private text.
- Prompt quality samples pass the established naturalness/faithfulness bar.
- Final internal regression shows no obvious review, privacy, security, or billing risk.

## Test commands

```text
cd app && flutter analyze
cd app && flutter test
cd backend && python -m pytest
cd app && flutter build appbundle --release <production dart-defines>
```

Also rerun the complete internal-test manual matrix, representative slow/offline paths, low-end performance checks, and prompt-quality sample set.

## Codex review checklist

- [ ] Errors/loading/retry states are complete and do not permit duplicate actions.
- [ ] Logs/analytics are useful but contain no private bodies or secrets.
- [ ] UI/accessibility/performance changes preserve the single planned style.
- [ ] Prompt tuning preserves API contracts, meaning, and natural English quality.
- [ ] Billing/auth/security invariants remain unchanged and regression tests pass.
- [ ] No large or future feature was introduced.

## Claude Code implementation prompt

```text
Polish only the existing MVP according to docs/PHASE_7_CHECKLIST.md. Prioritize
error UX, privacy-safe observability, quality, accessibility, performance, and
regression stability. Do not add features or alter billing contracts.
```

## Codex review prompt

```text
Perform the final Phase 7 regression and launch-readiness review against
docs/PHASE_7_CHECKLIST.md. Focus on error UX, privacy-safe logs, performance,
quality, and invariant preservation. Return PASS or NEEDS CHANGES.
```

