# Phase 2 Checklist — Anonymous Authentication

Source of truth: `docs/ReplyWise_development_plan.md`

## Phase goal

Establish a stable anonymous identity and resilient access/refresh-token lifecycle before any protected business API is used.

## Allowed scope

- Anonymous user creation, stable `appUserId`/`deviceId`, JWT access and refresh tokens, secure storage, `/v1/me`, middleware, and Dio 401 recovery.
- Auth state, startup orchestration, bounded retry/error behavior, and auth tests.

## Not allowed yet

- AI generation, usage deduction, paid billing, RevenueCat purchase logic, entitlement sync, credit sync, or functional paywall gating.
- Email/social login or account merging.

## Required Flutter work

- Generate UUID `appUserId` once and store it in `flutter_secure_storage`; keep a supporting device identifier.
- Store access/refresh tokens securely, never in ordinary preferences or logs.
- A single Riverpod auth service owns states: unauthenticated, authenticating, authenticated, refreshing, token_expired, and error.
- Startup: use stored access token with `/v1/me`; otherwise call anonymous auth; refresh expired access and retry; if refresh fails, recover through anonymous auth using the same `appUserId`.
- Dio adds bearer tokens to protected calls and performs one single-flight refresh for concurrent 401 responses, queues/replays requests, and uses bounded retries.
- Offline/auth failure reaches a recoverable UI state; no infinite loop or white screen.

## Required backend work

- `POST /v1/auth/anonymous`: accepts `deviceId`, `appUserId`, and `platform`; finds/creates by `appUserId`; returns access token, refresh token, `expiresIn: 604800`, and initial `me`.
- `POST /v1/auth/refresh`: validates refresh token and returns a usable new access token.
- `GET /v1/me`: requires bearer authentication and derives user identity only from the token.
- JWT includes `user_id`, `app_user_id`, peppered `device_hash`, `iat`, `exp`, `jti`, and token-version support.
- `/health` and anonymous auth remain public; protected routes reject missing or forged tokens.
- Secrets come from backend environment variables and differ between environments.

## Required files/folders

- Flutter auth application/data/domain structure, secure token storage, auth repository/service, and Dio interceptor integration.
- Backend auth routes, token/security service, user persistence needed for anonymous identity, schemas, dependencies/middleware, and tests.

## API/data/security notes

- `/v1/auth/anonymous` is the only user-creation endpoint.
- `appUserId` is an identifier, not a credential; never accept client premium state.
- `device_hash = SHA-256(deviceId + SERVER_PEPPER)`; never expose pepper or raw secrets.
- Keep refresh bounded and single-flight. MVP may use fixed refresh plus token version; fine-grained rotation is not required here.

## Acceptance criteria

- First launch obtains and stores tokens; restart retains the same backend user.
- Access expiry refreshes and retries automatically.
- Failed refresh recovers through anonymous auth without changing the user anchor.
- Concurrent 401s trigger one refresh; offline failure terminates cleanly.
- Missing/forged tokens return 401; `/v1/me` ignores spoofed identity headers.

## Test commands

```text
cd app && flutter analyze
cd app && flutter test
cd backend && python -m pytest
```

Tests cover first launch, persistence, valid/invalid tokens, expiry, refresh success/failure, concurrent 401s, and offline bounded failure.

## Codex review checklist

- [ ] Stable identifiers and tokens are securely persisted and never logged.
- [ ] Token-derived identity and endpoint access rules are enforced.
- [ ] Single-flight refresh/replay has no recursion, deadlock, or infinite retry.
- [ ] Anonymous recovery preserves `appUserId`.
- [ ] No later-phase AI or billing behavior was added.
- [ ] Auth tests and baseline suites pass.

## Claude Code implementation prompt

```text
Implement only anonymous authentication from docs/PHASE_2_CHECKLIST.md.
Prioritize secure storage, token-derived identity, single-flight refresh, and
bounded failure. Do not add AI, usage, entitlement, or purchase logic. Run tests.
```

## Codex review prompt

```text
Review Phase 2 auth only. Trace first launch, restart, expiry, concurrent 401,
refresh failure, and forged-token paths against docs/PHASE_2_CHECKLIST.md.
Return PASS or NEEDS CHANGES with blocking security/correctness issues.
```

