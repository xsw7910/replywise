# Phase 3 Checklist — AI Core

Source of truth: `docs/ReplyWise_development_plan.md`

## Phase goal

Complete authenticated Reply, Polish, and Explain generation end to end, with validated inputs, structured outputs, and frontend result presentation.

## Allowed scope

- `/v1/reply`, `/v1/polish`, `/v1/explain`, AI service/model router, prompts, parsing/retry, input validation, and planned error handling.
- Flutter repositories/controllers, result cards, copy behavior, loading/errors, and Reply Explain bottom sheet.
- Fake usage fields may be returned; real deduction/idempotency belongs to Phase 4.

## Not allowed yet

- Free-use or credit deduction, paywall enforcement, idempotent billing, RevenueCat subscriptions, consumable purchases, or production release work.

## Required Flutter work

- Reply sends incoming text, `guidance`, App-interface `guidanceLang`, fixed `outputLang: en`, and audience settings; renders Professional/Friendly/Short cards plus `why`.
- Polish sends draft, direction/custom guidance, and interface language; renders `polished` plus `changes`.
- Explain button remains in Reply and opens a bottom sheet with meaning, tone, hidden meaning, and 1–3 suggested English replies.
- “Use” on a suggestion fills guidance; explanation can be copied. Generated copy shows `Copied`, does not auto-send, and does not switch apps.
- Enforce matching client max lengths and clear loading, validation, retry, and backend-error states.

## Required backend work

- All three endpoints require bearer authentication; model credentials remain backend-only.
- Reply emits exactly three labeled English versions and `why` in the App interface language.
- Polish preserves meaning, adds no facts, and returns English `polished` plus localized `changes`.
- Explain returns localized `meaning/tone/hiddenMeaning` and 1–3 English `suggestedReplies`; it consumes zero units.
- Typed guidance language is model-detected/understood automatically; never require users to choose it.
- Parse structured JSON, strip JSON fences, retry once with “Return valid JSON only,” then return `MODEL_PARSE_ERROR`.
- Validate: incoming/draft non-empty and ≤4000, guidance non-empty and ≤1000, Polish custom ≤500; map planned validation/model errors.
- Add the planned lightweight backend safety gate. Do not save request or generated bodies.

## Required files/folders

- Flutter feature data/application/domain/presentation pieces for Reply, Polish, and embedded Explain.
- Backend routes, Pydantic schemas, AI service, model provider/router abstraction, prompt definitions, and tests.

## API/security notes

- MVP output is always English even if a client sends another `outputLang`.
- Explain is not a route. It does not require generation idempotency in this phase.
- Explain daily DB rate limiting is part of the documented AI endpoint behavior; keep it independent from billing.
- Fixed prompt prefix precedes variable content; capture prompt/cache metadata without storing body text.

## Acceptance criteria

- Authenticated app generates and displays Reply, Polish, and embedded Explain results.
- Outputs follow the exact structures and language rules; no invented facts.
- Empty/oversized input is rejected before model invocation.
- Malformed model JSON retries once and then returns the planned error.
- Model keys are absent from Flutter and request/response bodies are not persisted.

## Test commands

```text
cd app && flutter analyze
cd app && flutter test
cd backend && python -m pytest
```

Tests cover payloads, output parsing, JSON-fence/retry failure, validation limits, error mapping, authentication, language rules, and Explain structure/rate limit.

## Codex review checklist

- [ ] Endpoint contracts and Flutter DTOs agree.
- [ ] `guidance` naming and all three language rules are correct.
- [ ] Explain is embedded in Reply and suggestions fill guidance.
- [ ] Validation occurs on both sides and model failures are recoverable.
- [ ] No client model key, body persistence, or Phase 4 billing logic exists.
- [ ] Tests pass with model calls mocked.

## Claude Code implementation prompt

```text
Implement only the authenticated AI core in docs/PHASE_3_CHECKLIST.md. Keep
usage fake/non-deducting, output English, Explain embedded in Reply, and model
keys backend-only. Mock model calls in tests and run all listed commands.
```

## Codex review prompt

```text
Review Phase 3 contracts, prompts, validation, language behavior, UI integration,
and error paths against docs/PHASE_3_CHECKLIST.md. Confirm no real billing was
introduced. Return PASS or NEEDS CHANGES with exact files.
```

