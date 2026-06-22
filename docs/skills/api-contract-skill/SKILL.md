---
name: api-contract-skill
description: ReplyWise API contract rules — camelCase JSON, error codes, request/response schemas, validation, and Flutter/backend DTO alignment.
version: 1.0
---

## Purpose

Ensure every API endpoint speaks a consistent contract that both the Flutter client and backend agree on, with no silent mismatches or undocumented error codes.

## When to use

When defining, implementing, or reviewing any backend endpoint or Flutter repository/DTO.

## Core rules

1. **camelCase JSON** for all request and response fields. Backend uses `alias_generator=to_camel` with `populate_by_name=True`. Flutter DTOs use the same camelCase field names.
2. **Naming**: use `guidance` (never `instruction`) in all APIs, state, and UI.
3. **`usage` block** is present in every generation response (`/v1/reply`, `/v1/polish`, `/v1/explain`). It contains `creditsUsed`, `source`, `freeUsesLeft` (nullable), `paidCredits`.
4. **`freeUsesLeft` is `int?`** — `null` for premium users in all endpoints, always.
5. **`outputLang`** is fixed to `"en"` in MVP. Backend ignores client-sent value; client sends `"en"`.
6. **`guidanceLang`** carries the App interface language (not the user's typing language). Used to control the language of `why`, `changes`, and `explain` prose.
7. **Error shape** is always `{"error": {"code": "...", "message": "..."}}`. Never vary this structure.
8. **Error codes** are from the fixed table in `AI_CONTEXT.md` §6.8. No ad-hoc codes.
9. **`X-Idempotency-Key`** is required on `POST /v1/reply` and `POST /v1/polish`. Not required on `POST /v1/explain`.
10. **Identity from token only.** Request body must never carry `userId`, `isPremium`, or `appUserId` as trusted fields.

## Implementation rules

- Backend Pydantic schemas use `ConfigDict(alias_generator=to_camel, populate_by_name=True)`.
- Flutter `fromJson` factory maps camelCase JSON keys directly to Dart field names.
- Validation limits (enforced on both sides):
  - `incoming`, `draft`: non-empty after trim, ≤ 4000 chars
  - `guidance`: non-empty after trim, ≤ 1000 chars
  - `custom` (polish direction): ≤ 500 chars
- `VALIDATION_ERROR` (400) for empty/missing required fields.
- `INPUT_TOO_LONG` (400) for over-limit fields.
- `source` field: `"free"` | `"credit"` | `null` (premium). Never omit it from generation responses.
- `creditsUsed`: `1` on success for non-premium, `0` for premium. Never omit.
- `/v1/me` response includes: `userId`, `appUserId`, `isPremium`, `freeUsesLimit`, `freeUsesUsed`, `freeUsesLeft`, `paidCredits`, `upgradeRequired`.

## Common mistakes

- Returning snake_case JSON fields instead of camelCase.
- Omitting `usage` block from polish response (it must match reply).
- Using `instruction` instead of `guidance` in field names.
- Trusting `isPremium` from the request body.
- Returning a different error shape (`{"detail": "..."}`) from domain errors.
- `freeUsesLeft` returned as `0` instead of `null` for premium users.
- Adding a new error code not in the defined table without updating both sides.

## Review checklist

- [ ] All JSON keys are camelCase on wire (check alias_generator and Flutter fromJson).
- [ ] `usage` block present in every generation response with all four fields.
- [ ] `freeUsesLeft` is `null` for premium in all endpoints.
- [ ] `source` and `creditsUsed` present and semantically correct.
- [ ] Error shape is `{"error": {"code": "...", "message": "..."}}` for all error cases.
- [ ] Error code is from the defined table.
- [ ] `X-Idempotency-Key` required/enforced on reply and polish.
- [ ] No identity fields in request body.

## Acceptance criteria

- Backend integration tests verify camelCase response keys.
- Flutter repository tests parse the response DTO without null errors.
- No undocumented error codes appear in the codebase.

## Example Claude Code prompt

```text
Read docs/AI_CONTEXT.md and docs/skills/api-contract-skill/SKILL.md.
Add the [endpoint] ensuring camelCase JSON, usage block in response,
freeUsesLeft nullable, and error shape from the defined table.
```

## Example Codex review prompt

```text
Review [router/repository] against docs/skills/api-contract-skill/SKILL.md.
Check camelCase alignment, usage block completeness, freeUsesLeft nullability,
error shape, and error code table compliance. Return PASS or NEEDS CHANGES.
```

## Related documents

- `docs/AI_CONTEXT.md` — naming rules, billing rules summary
- `docs/skills/billing-usage-skill/SKILL.md` — usage block semantics
- `docs/ReplyWise_development_plan.md` §6 — full API contract with examples
