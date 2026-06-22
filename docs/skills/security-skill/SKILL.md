---
name: security-skill
description: ReplyWise security rules — JWT auth, authorization, secrets management, production safety, and no client-side trust.
version: 1.0
---

## Purpose

Prevent authentication bypass, privilege escalation, secret leakage, and client-side trust bugs across the Flutter app and FastAPI backend.

## When to use

When building or reviewing anything that touches auth, tokens, identity, secrets, entitlement, or production configuration.

## Core rules

1. **Flutter never calls a model provider directly.** All LLM calls go through the backend. Model API keys exist only on the backend.
2. **Never trust client-supplied identity.** Backend derives `user_id` exclusively from the verified JWT. Request body fields like `isPremium`, `appUserId`, or `userId` are ignored for authorization decisions.
3. **Never trust client-supplied premium status.** Whether a user can generate is determined by backend-verified entitlement state, not by any field the client sends.
4. **Backend verifies entitlement.** RevenueCat state is checked server-side using the RevenueCat secret key. Client-side RevenueCat state is for immediate UI only.
5. **Secrets never in Flutter.** `AppConfig` carries only public build-time values. JWT tokens go in `flutter_secure_storage`; never in `SharedPreferences` or plaintext.
6. **Secrets never committed to git.** `.env` files, `JWT_SECRET`, `SERVER_PEPPER`, RevenueCat secret keys, and production credentials must not appear in version control.
7. **`device_hash = SHA-256(deviceId + SERVER_PEPPER)`.** Raw device IDs are never stored; they are hashed with a server-side pepper that lives only in environment variables.
8. **All `/v1/*` endpoints require `Authorization: Bearer <token>`**, except `/health` and `/v1/auth/anonymous`.
9. **Single-flight token refresh.** Only one refresh request flies at a time; concurrent 401s queue and reuse the result to prevent refresh storms.
10. **`is_blocked` flag** in the `users` table allows server-side user suspension without key rotation.

## Implementation rules

- JWT payload contains: `user_id`, `app_user_id`, `device_hash`, `iat`, `exp`, `jti`.
- Access token TTL: 7 days (604,800 s). Refresh token TTL: longer.
- `JWT_SECRET` and `SERVER_PEPPER` must differ between dev and production environments.
- `get_current_user` FastAPI dependency raises `UNAUTHENTICATED` (401) if token is absent, invalid, expired, or if the user is blocked.
- `token_version` on the `users` row allows revoking all existing tokens for a user by incrementing the version.
- Debug endpoints (`/v1/debug/*`) must be mounted only when `settings.env == "dev"`. Production must never expose them.
- Never log raw request bodies containing user messages, guidance, or draft text.
- `UNAUTHENTICATED` (401) → client refreshes or re-authenticates anonymously. `TOKEN_EXPIRED` is a subtype that triggers automatic refresh per §3.7.

## Common mistakes

- Reading `isPremium` or `userId` from the request body for authorization.
- Storing JWT in `SharedPreferences` (not encrypted) instead of `flutter_secure_storage`.
- Hardcoding `JWT_SECRET` or any secret in source code.
- Mounting `/v1/debug/canonicalize` in production.
- Not guarding `is_blocked` in `get_current_user` — blocked users can still call APIs.
- Multiple concurrent refresh calls racing — must use a single-flight `Completer`.
- Logging or storing user message bodies or generated replies.

## Review checklist

- [ ] No LLM API key in Flutter code or `AppConfig`.
- [ ] `get_current_user` verifies JWT and checks `is_blocked`.
- [ ] No identity or premium fields from request body used for authorization.
- [ ] JWT stored in `flutter_secure_storage`; no plaintext storage.
- [ ] No `.env`, JWT secret, or pepper in committed files.
- [ ] Debug endpoints gated on `settings.env == "dev"`.
- [ ] Single-flight refresh in auth interceptor.
- [ ] No user message bodies in logs.

## Acceptance criteria

- Unauthenticated request to any `/v1/*` protected endpoint returns 401.
- Sending `isPremium: true` in a request body has no effect on billing behavior.
- `python -m pytest` includes a test that verifies protected endpoints reject missing tokens.
- No secrets appear in `git log` or committed files.

## Example Claude Code prompt

```text
Read docs/AI_CONTEXT.md and docs/skills/security-skill/SKILL.md.
Implement [auth feature] ensuring JWT-only identity, no client premium trust,
and secrets only from environment variables.
```

## Example Codex review prompt

```text
Review [auth/entitlement code] against docs/skills/security-skill/SKILL.md.
Check JWT-only identity derivation, no client premium trust, secret handling,
debug endpoint gating, and single-flight refresh. Return PASS or NEEDS CHANGES.
```

## Related documents

- `docs/AI_CONTEXT.md` — architecture and security rules, never trust client headers
- `docs/AI_WORKFLOW.md` — never commit secrets
- `docs/skills/billing-usage-skill/SKILL.md` — premium skip logic (must be backend-verified)
- `docs/ReplyWise_development_plan.md` §0.3, §3.7, §3.8 — auth model, JWT spec, pepper
