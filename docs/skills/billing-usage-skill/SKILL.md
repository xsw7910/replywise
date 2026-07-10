---
name: billing-usage-skill
description: ReplyWise billing rules — free/credit/premium access order, idempotency, atomic deduction, rollback, and concurrency-safe rate limiting.
version: 1.0
---

## Purpose

Prevent billing bugs: no overdraw, no double-deduction, correct source-aware rollback, and rate limits that survive restarts and concurrent requests.

## When to use

When building or reviewing anything that touches `usage_summary`, `usage_events`, `idempotency_keys`, or rate limiting.

## Core rules

1. **Access order**: premium first → free uses → paid credits → `PAYWALL_REQUIRED`. Never deviate.
2. **Premium skips all deductions.** `free_uses_used` and `paid_credits` are untouched for premium users.
3. **`free_uses_used` is factual**, never reset. It increments only when a non-premium user deducts from the free pool. It never changes during premium.
4. **`freeUsesLeft` is computed dynamically**: `isPremium ? null : max(0, limit - used)`. Never stored.
5. **Atomic deduction**: use `UPDATE usage_summary SET free_uses_used = free_uses_used + 1 WHERE free_uses_used < free_uses_limit`. No SELECT then UPDATE.
6. **Source-aware rollback**: rollback returns the deduction to the exact pool it came from (`free` → decrement `free_uses_used`; `credit` → increment `paid_credits`).
7. **Idempotency key**: client sends UUID v4 `X-Idempotency-Key` per new operation. Same key + same hash → replay. Same key + different hash → `IDEMPOTENCY_CONFLICT`. Failed key → retry allowed (delete and reprocess).
8. **Short transactions**: commit deduction + idempotency key before LLM call. Commit result or rollback after. Never hold an open session during the LLM call.
9. **Post-commit rate check**: after committing the processing key, count committed idempotency keys in the sliding window. If `count > limit`, rollback and raise `RATE_LIMITED`. This prevents two concurrent requests both slipping through before either commits.
10. **Rate limiting ≠ billing**: they are independent counts. Idempotent replays and 409s do not count toward rate limits.
11. **`RATE_LIMITED` vs `PAYWALL_REQUIRED`**: `RATE_LIMITED` = too frequent (429); `PAYWALL_REQUIRED` = quota exhausted (402). Never conflate.

## Implementation rules

- `usage_service.py` is the single location for all deduction, rollback, and rate-limit logic.
- `summary_dict(summary, is_premium)` is the single source of truth for `freeUsesLeft`, `upgradeRequired`, `isPremium`. No inline recalculation in routers.
- `finish_generation` calls `summary_dict` and appends `creditsUsed` and `source` for the response.
- `GET /v1/me` calls `summary_dict` — no duplicated calculation.
- Rate limit window for reply/polish: sliding 1-minute window on `IdempotencyKey.created_at`.
- Rate limit for explain: daily count on `usage_events` where `endpoint='explain'`.
- `FREE_LIFETIME_LIMIT` comes from `settings.free_lifetime_limit` — never hardcoded.
- `cost_usd` column in `usage_events` is nullable; populate when token cost is known.

## Common mistakes

- Checking rate limit before committing the idempotency key — concurrent requests both pass the pre-commit check.
- Resetting `free_uses_used` when a user subscribes — prohibited.
- Returning `freeUsesLeft=0` instead of `null` for premium users.
- Sharing rate-limit count with billing deduction count.
- Rolling back to wrong pool (e.g., always decrementing `free_uses_used` regardless of `source`).
- Using `count(usage_events)` for rate limiting instead of `count(idempotency_keys)` — events are committed after the model call, creating a race window.
- Inline `freeUsesLeft` calculation in the router duplicating `summary_dict`.

## Review checklist

- [ ] Access order: premium → free → credit → paywall.
- [ ] `free_uses_used` never modified during premium.
- [ ] `freeUsesLeft` computed from `summary_dict`, not inline.
- [ ] Atomic `UPDATE ... WHERE` for deduction; no SELECT-then-UPDATE.
- [ ] Rollback uses the recorded `source`; restores correct pool.
- [ ] Rate check is post-commit (counts committed idempotency keys).
- [ ] `RATE_LIMITED` and `PAYWALL_REQUIRED` are distinct and correct.
- [ ] `summary_dict` is the single source for both generation responses and `/v1/me`.

## Acceptance criteria

- Three sequential free uses succeed; fourth returns `PAYWALL_REQUIRED`.
- Two concurrent requests cannot both overdraw (atomic UPDATE prevents it).
- Two concurrent requests cannot both succeed when `rate_limit=1`.
- Model failure restores the correct pool; `freeUsesUsed` returns to its pre-request value.
- Duplicate idempotency key replays; different payload conflicts.

## Example Claude Code prompt

```text
Read docs/AI_CONTEXT.md and docs/skills/billing-usage-skill/SKILL.md.
Fix [billing issue] ensuring post-commit rate check, atomic deduction,
source-aware rollback, and summary_dict as single source of truth.
```

## Example Codex review prompt

```text
Audit [usage_service.py / endpoint] against docs/skills/billing-usage-skill/SKILL.md.
Trace free, credit, concurrent, duplicate, and rate-limit paths.
Verify no overdraw, correct rollback, post-commit rate check, and single summary_dict.
Return PASS or NEEDS CHANGES.
```

## Related documents

- `docs/AI_CONTEXT.md` — billing rules summary
- `docs/skills/fastapi-backend-skill/SKILL.md` — short-transaction pattern
- `docs/skills/testing-review-skill/SKILL.md` — concurrency test patterns
- `docs/ReplyWise_development_plan.md` §3.1, §3.6, §3.9 — full billing spec
