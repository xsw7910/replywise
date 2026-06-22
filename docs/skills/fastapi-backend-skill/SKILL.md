---
name: fastapi-backend-skill
description: FastAPI backend structure, service/router/model separation, async I/O, error handling, and config rules for ReplyWise.
version: 1.0
---

## Purpose

Keep backend code organized and async-correct: short transactions, no DB connection during LLM calls, consistent error responses, and config from environment variables only.

## When to use

When building or reviewing any backend router, service, model, schema, dependency, or config.

## Core rules

1. **Routers** only parse requests, call services, and return responses. No business logic in routers.
2. **Services** contain business logic (usage, idempotency, AI orchestration). They accept a `db: AsyncSession` argument and return domain objects or raise `ApiException`.
3. **Models** (`app/models/`) are SQLAlchemy `mapped_column` ORM classes. No Pydantic in models.
4. **Schemas** (`app/schemas/` or inline in routers) are Pydantic `BaseModel` classes used for request/response validation only.
5. **Short transactions**: commit and release the DB session before any LLM call. Never hold an open session during `await ai_service.complete(...)`.
6. **All I/O is async**: use `AsyncSession` (`sqlalchemy.ext.asyncio`), `httpx` for HTTP, `asyncpg` driver in production. Never use synchronous DB drivers or `requests`.
7. **Config from environment only**: all secrets and configurable values come from `app/config.py` → `Settings(BaseSettings)`. No hardcoded credentials anywhere.
8. **`ApiException`** is the single raise point for business errors. Routers must not raise raw `HTTPException` for domain errors — use `ApiException` with an error code from the defined table.
9. **No LLM call inside a DB transaction.** Pattern: (1) short transaction: deduct + insert idempotency key → commit; (2) call LLM outside any session; (3) short transaction: write result or rollback → commit.

## Implementation rules

- Router files live in `app/api/v1/`. Each router has a single `APIRouter(prefix="/v1", tags=["..."])`.
- `get_current_user` dependency parses and verifies JWT. Never trust identity from request body or headers.
- `get_db` dependency yields an `AsyncSession`; it must not be held across LLM calls.
- Use `Mapped[T]` and `mapped_column(...)` for all ORM columns (SQLAlchemy 2.0 style).
- Connection pool: `min_size=5, max_size=20` for asyncpg in production.
- LLM calls use explicit `timeout=15s` via httpx.
- Debug endpoints (e.g., `/v1/debug/canonicalize`) mount only when `settings.env == "dev"`.
- `python -m pytest` must pass with no warnings before commit.

## Common mistakes

- Awaiting LLM inside `async with session.begin()` — exhausts connection pool under concurrency.
- Using `SELECT` then `UPDATE` for deduction instead of atomic `UPDATE ... WHERE`.
- Raising `HTTPException` directly for domain errors instead of `ApiException`.
- Reading secrets from `os.environ` directly instead of through `settings`.
- Synchronous DB driver (`psycopg2`) blocking the event loop.
- Missing `@router.post(...)` response model causing unvalidated response leakage.

## Review checklist

- [ ] No LLM call inside an open DB session/transaction.
- [ ] All deductions use atomic `UPDATE ... WHERE` (no read-modify-write).
- [ ] All secrets read from `Settings`, not hardcoded.
- [ ] `ApiException` used for all domain errors; no bare `HTTPException` for business logic.
- [ ] All DB I/O uses `AsyncSession`; no synchronous calls.
- [ ] Debug endpoints guarded by `settings.env == "dev"`.
- [ ] `python -m pytest` passes.

## Acceptance criteria

- `python -m pytest` passes with no errors.
- No synchronous DB or HTTP calls in the codebase (Grep for `psycopg2`, `requests.`).
- No open session during LLM call path.

## Example Claude Code prompt

```text
Read docs/AI_CONTEXT.md and docs/skills/fastapi-backend-skill/SKILL.md.
Implement [endpoint] following short-transaction pattern.
No LLM call inside a DB transaction. Raise ApiException for domain errors.
```

## Example Codex review prompt

```text
Review [service/router].py against docs/skills/fastapi-backend-skill/SKILL.md.
Check transaction boundaries, async correctness, atomic deduction,
secret handling, and error code usage. Return PASS or NEEDS CHANGES.
```

## Related documents

- `docs/AI_CONTEXT.md` — async I/O rule, no storing message bodies
- `docs/skills/billing-usage-skill/SKILL.md` — transaction pattern for deduction/rollback
- `docs/skills/security-skill/SKILL.md` — JWT verification, no client trust
- `docs/ReplyWise_development_plan.md` §5, §3.6 — stack choices, transaction pattern
