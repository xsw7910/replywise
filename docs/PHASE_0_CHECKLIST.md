# Phase 0 Checklist — Skeleton and Health Check

Source of truth: `docs/ReplyWise_development_plan.md`

Status: **Completed in the current repository.** Keep the review items for regression checks.

## Phase goal

Run a Flutter Android skeleton and a local FastAPI skeleton, with Flutter successfully reading `GET /health` from `http://10.0.2.2:8000`.

## Allowed scope

- Flutter project structure, Riverpod bootstrap, `go_router`, placeholder screens, theme tokens, and configuration.
- FastAPI app/config/router skeleton, health endpoint, requirements, container files, and health tests.
- Dio health client, repository, providers/controller, status UI, and Android networking configuration.

## Not allowed yet

- Authentication, AI/model calls, database business logic, usage counting, subscriptions, purchases, credits, entitlement logic, or functional paywall behavior.

## Required Flutter work

- `main.dart` only boots `ProviderScope` and `ReplyWiseApp`; app composition lives in `app.dart`.
- Reply, Polish, and Settings placeholder routes work through `go_router`.
- `AppConfig` reads `REPLY_BACKEND_BASE_URL`, `REPLY_ENV`, `REVENUECAT_ANDROID_API_KEY`, and `REVENUECAT_ENTITLEMENT_ID`.
- Default backend URL is `http://10.0.2.2:8000`.
- Dio uses `AppConfig.backendBaseUrl`, bounded timeouts, and JSON accept headers.
- Health repository parses `status` and `service`; controller exposes loading/data/error and refresh.
- Main Android manifest grants `INTERNET`; debug manifest alone permits cleartext local HTTP.

## Required backend work

- FastAPI app factory/application and settings module exist.
- `GET /health` returns HTTP 200 and `{"status":"ok","service":"reply-backend"}`.
- `requirements.txt`, `Dockerfile`, and `docker-compose.yml` exist.
- A pytest health test verifies status and body.

## Required files/folders

- `app/lib/main.dart`, `app/lib/app.dart`, `app/lib/core/config/`, `core/network/`, `core/router/`, `core/theme/`, `core/widgets/`, and feature folders.
- Health repository/controller under the selected feature structure.
- `backend/app/main.py`, `backend/app/config.py`, `backend/app/api/health.py`, and `backend/tests/test_health.py`.
- `backend/requirements.txt`, `backend/Dockerfile`, and `backend/docker-compose.yml`.

## Acceptance criteria

- Android emulator opens the app and navigation placeholders work.
- Flutter displays a successful local backend health response and a useful error state when unavailable.
- Release/main configuration does not globally permit cleartext traffic.
- Flutter analysis/tests and backend pytest pass.

## Test commands

```text
cd app && flutter analyze
cd app && flutter test
cd backend && python -m pytest
```

Manual: start FastAPI on port 8000, run the Android emulator, and verify Settings reports `status: ok` and `service: reply-backend`.

## Codex review checklist

- [ ] Bootstrap, Riverpod, routes, placeholders, and AppConfig match this phase.
- [ ] Dio/repository/controller responsibilities are separated and errors reach the UI.
- [ ] Android permissions allow debug local HTTP without enabling cleartext globally.
- [ ] `/health` contract and pytest match exactly.
- [ ] No later-phase business logic was introduced.
- [ ] All listed tests pass.

## Claude Code implementation prompt

```text
Read docs/AI_CONTEXT.md and docs/PHASE_0_CHECKLIST.md. Implement or repair
only the Phase 0 skeleton and local /health path. Do not add later-phase logic.
Run Flutter analysis/tests and backend pytest, then report changed files.
```

## Codex review prompt

```text
Review only Phase 0 against docs/PHASE_0_CHECKLIST.md. Verify files, the exact
/health response, Android local-network policy, and all listed tests. Return
PASS or NEEDS CHANGES with blocking issues and exact files.
```

