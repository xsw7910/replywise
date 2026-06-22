---
name: testing-review-skill
description: ReplyWise test patterns — unit, controller, API integration, and concurrency tests; blocking vs non-blocking review classification.
version: 1.0
---

## Purpose

Define what tests are required for each layer, how to write them correctly, and how to classify review findings as blocking or non-blocking.

## When to use

When writing tests for any layer, or when conducting a code review with a PASS/NEEDS CHANGES verdict.

## Core rules

1. **Blocking issues** must be fixed before commit: violated phase contract, broken required behavior, billing correctness, data integrity, security, build failure, test failure.
2. **Non-blocking issues** may be deferred: naming, maintainability, test depth beyond requirements, UX polish, optimization.
3. **Never skip a failing test** to make CI green — fix the root cause.
4. **Test commands** (run all before commit):
   - `cd app && flutter analyze`
   - `cd app && flutter test`
   - `cd backend && python -m pytest`

## Backend test patterns

- **API integration tests** use `TestClient(app)` from `fastapi.testclient`. Each test creates its own user via `POST /v1/auth/anonymous`.
- **Concurrency tests** use `threading.Barrier(N)` to synchronize threads, then call `client.post()` simultaneously. Assert the combined outcome (e.g., `freeUsesUsed == success_count`).
- **Atomic deduction test**: assert that two concurrent requests do not overdraw (`freeUsesUsed == results.count(200)`).
- **Concurrency rate-limit test**: with `rate_limit=1` (monkeypatched), assert `results.count(200) < 2`.
- **Idempotency test**: same key + same payload → 200 replay with identical body; same key + different payload → 409.
- **Rollback test**: inject a failing AI service; assert `freeUsesUsed` returns to 0.
- Use `monkeypatch.setattr(settings, 'field', value)` to override config per test.

## Flutter test patterns

- **Repository unit tests**: subclass `ApiClient` to control responses without network. Test parsing, retry logic, and error propagation.
- **Controller unit tests**: use `ProviderContainer` with overrides for all providers that would touch the network (`replyRepositoryProvider`, `usageRepositoryProvider`, etc.). Use `_FakeRepo` classes extending the real repo class, overriding the async method.
- **Widget tests**: override underlying providers (`tokenStorageProvider`, `authRepositoryProvider`) with fakes — do not `overrideWithValue` a generated `AutoDisposeAsyncNotifierProvider` directly.
- **Idempotency retry tests**: create a fake `ApiClient` that throws `DioException` with `IDEMPOTENCY_CONFLICT` for N calls, then succeeds. Assert `callCount` and final result.
- **Bounded retry**: assert `callCount == 3` even when `failTimes > 3` (max 3 attempts).
- Always `addTearDown(container.dispose)` for every `ProviderContainer` created in a test.

## Common mistakes

- Creating a `ProviderContainer(parent: c)` without overriding all providers that touch `FlutterSecureStorage` — causes "Binding not initialized" or 30-second timeouts.
- Using `TestWidgetsFlutterBinding` when `ProviderContainer` suffices — prefer `ProviderContainer` for controller-only tests.
- Concurrent backend tests without `barrier.wait()` — threads may not actually run simultaneously.
- Asserting exact concurrent success count (e.g., `== 1`) when both could be rate-limited — assert `< 2` instead.
- `overrideWithValue` on a code-generated `AutoDisposeAsyncNotifierProvider` — use `overrideWith((ref) => FakeImpl())` instead.
- Testing billing behavior with mocked DB — always use real `TestClient` + real SQLite for billing tests.

## Review checklist

- [ ] All test commands pass: `flutter analyze`, `flutter test`, `python -m pytest`.
- [ ] Concurrency tests use `threading.Barrier` (backend) or simultaneous `ProviderContainer` calls (Flutter).
- [ ] Billing tests use real `TestClient`, not mocked DB.
- [ ] Every `ProviderContainer` in tests has `addTearDown(container.dispose)`.
- [ ] Retry tests assert `callCount` bounds, not just final result.
- [ ] Review verdict is PASS or NEEDS CHANGES with blocking/non-blocking classification.
- [ ] No test is skipped or marked `xfail` without documented reason.

## Acceptance criteria

- All three test commands exit 0.
- Concurrency tests demonstrate no overdraw and correct rate limiting under simultaneous load.
- Controller tests cover success, error-code surfacing, result preservation on error, and usage refresh behavior.

## Example Claude Code prompt

```text
Read docs/skills/testing-review-skill/SKILL.md.
Add [test type] for [feature] following the patterns for [layer].
Use ProviderContainer with fake overrides; no network calls in tests.
```

## Example Codex review prompt

```text
Review [test file(s)] against docs/skills/testing-review-skill/SKILL.md.
Verify test commands pass, concurrency patterns are correct, billing tests use real TestClient,
and ProviderContainer teardowns are present. Return PASS or NEEDS CHANGES with classification.
```

## Related documents

- `docs/AI_WORKFLOW.md` — issue classification (blocking/non-blocking), commit checklist
- `docs/skills/billing-usage-skill/SKILL.md` — what billing behavior to test
- `docs/skills/flutter-architecture-skill/SKILL.md` — ProviderContainer usage
- `docs/ReplyWise_development_plan.md` §3.6, §3.9 — idempotency and rate-limit behavior under test
