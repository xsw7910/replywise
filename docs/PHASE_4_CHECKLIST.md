# Phase 4 Checklist — Usage, Credits Foundation, and Idempotency

Source of truth: `docs/ReplyWise_development_plan.md`

## Phase goal

Make backend usage enforcement correct under retries, failures, and concurrency: 3 lifetime free uses, then existing paid credits, otherwise paywall required.

## Allowed scope

- Usage schema/state, `/v1/me` usage response, entitlement controller foundation, atomic accounting, idempotency, rollback, DB rate limits, cleanup, and usage tests.
- `paidCredits` balance and consumption foundation only; no purchase/grant flow yet.

## Not allowed yet

- RevenueCat subscriptions, trial/purchase execution, entitlement sync, consumable credit purchases, or `/v1/credits/sync`.

## Required Flutter work

- Parse backend-authoritative `isPremium`, nullable `freeUsesLeft`, `paidCredits`, and `upgradeRequired`.
- Send a cryptographically random UUID v4 `X-Idempotency-Key` per new Reply/Polish operation; reuse it only when retrying that same operation.
- Do not calculate or send `request_hash`.
- Handle `PAYWALL_REQUIRED`, `RATE_LIMITED`, and `IDEMPOTENCY_CONFLICT` distinctly; processing conflicts retry with the same key using bounded 1s/2s backoff, at most three times.
- Refresh `/v1/me` after generation and show free/paid balance correctly; premium displays “Premium,” not remaining uses.
- Regenerate is a new charged operation and warns non-premium users it consumes one use.

## Required backend work

- Tables: `users`, `usage_summary`, `usage_events`, and `idempotency_keys`; include planned columns/indexes and `paid_credits` foundation.
- `usage_events` includes source, prompt_version, cache_hit, success/error, token/cost inputs, timestamp, and `(user_id, endpoint, created_at)` index; never message bodies.
- `FREE_LIFETIME_LIMIT` defaults to 5 but comes from configuration.
- Backend canonicalizes validated payloads with `model_dump(mode="json")`, strips nulls then fills defaults, trims strings, recursively sorts keys, emits compact UTF-8 JSON, and hashes with SHA-256.
- Idempotency: succeeded+same hash replays; processing returns 409; same key+different hash conflicts; failed may retry. Expired records are cleaned by `expires_at`.
- In a short transaction, create processing state and atomically pre-deduct free first, then credit. If neither is available, return `PAYWALL_REQUIRED` without model invocation.
- Run the model outside any DB transaction/session. In a second short transaction, save success or rollback the exact source and record failure.
- Premium bypasses both deductions; `free_uses_used` never resets or changes during premium; premium `freeUsesLeft` is always null.
- DB rate limits are independent from billing: Reply/Polish 8 actual model entries per user/minute; Explain 10/user/day. Idempotent replay and 409 do not count.
- Use `RATE_LIMITED` only for rate limits; the sixth unpaid generation returns `PAYWALL_REQUIRED`.

## Required files/folders

- Backend models/migrations or initialization, usage/idempotency services, repository queries, config, cleanup task, API error mapping, and tests.
- Flutter entitlement/usage domain, controller, repository integration, badge/gating UI, and tests.

## Data/security notes

- Atomic `UPDATE ... WHERE` is mandatory; never SELECT then UPDATE for deduction.
- Free-use and paid-credit pools must roll back to their original source.
- Rate-limit counts and billing counts are separate concepts.
- Dev canonicalization endpoint may exist only in dev and must not mount in production.

## Acceptance criteria

- New user gets exactly five free successful generations across Reply/Polish.
- Fourth use with no credits returns 402 `PAYWALL_REQUIRED`; existing credits are used only after free uses.
- Concurrent requests cannot overspend; duplicate requests call the model and deduct at most once.
- Model failure restores the correct pool; failed idempotency does not strand the user.
- Premium simulation preserves historical free count and existing credits.
- Canonical null/omitted, numeric, and Enum variants hash consistently.
- Cleanup removes expired idempotency records; DB rate limits survive restart.

## Test commands

```text
cd app && flutter analyze
cd app && flutter test
cd backend && python -m pytest
```

Also run concurrent tests with `asyncio.gather` and the planned ≥10-user generate/retry load test; verify no overdraw, locked database, or exhausted connection pool.

## Codex review checklist

- [ ] Access order and nullable premium semantics are exact.
- [ ] Idempotency state/hash behavior prevents replay and key reuse bugs.
- [ ] Transactions are short and model calls hold no DB connection.
- [ ] Deduction/rollback are atomic and source-aware under concurrency.
- [ ] Billing and DB rate limits are independent; error codes are distinct.
- [ ] No RevenueCat purchase/grant logic was introduced.
- [ ] Unit, integration, and concurrency tests pass.

## Claude Code implementation prompt

```text
Implement only Phase 4 from docs/PHASE_4_CHECKLIST.md. Treat atomic accounting,
backend-only canonical hashes, source-aware rollback, and concurrency tests as
blocking correctness requirements. Do not add RevenueCat purchase flows.
```

## Codex review prompt

```text
Audit Phase 4 as a billing/concurrency review. Trace free, credit, premium,
duplicate, processing, failure, rate-limit, and concurrent paths. Return PASS
or NEEDS CHANGES with reproducible blocking issues and exact files.
```

