# Local Mock Testing

ReplyWise supports dev/test-only local testing for Reply, Explain, Polish, and account usage controls without OpenAI, RevenueCat, or Google Play purchases.

## Backend

Start the backend in a dev or test environment with both local testing flags enabled:

```powershell
$env:APP_ENV = "dev"
$env:MOCK_AI_ENABLED = "true"
$env:DEV_TOOLS_ENABLED = "true"
cd backend
uvicorn app.main:app --reload
```

`MOCK_AI_ENABLED=true` selects deterministic fake AI responses for:

- `POST /v1/reply`: Professional, Friendly, and Short versions
- `POST /v1/explain`: meaning, tone, hidden meaning, and suggested replies
- `POST /v1/polish`: polished text and changes

Validation, bearer auth, usage deduction, idempotency, rate limiting, and normal error handling still run.

## Flutter

Run the app against the local backend:

```powershell
cd app
flutter run `
  --dart-define=REPLY_BACKEND_BASE_URL=http://10.0.2.2:8000 `
  --dart-define=REPLY_ENV=dev `
  --dart-define=DEV_TOOLS_ENABLED=true
```

Use `http://10.0.2.2:8000` for the Android emulator. Use your machine LAN IP for a physical device.

## What To Test

1. Open Reply and generate a reply. The backend returns deterministic Professional, Friendly, and Short versions.
2. Open Explain and explain a message. The backend returns deterministic explanation sections.
3. Open Polish and polish a draft. The backend returns deterministic polished text and changes.
4. Open Settings, then Developer Testing.
5. Tap Reset free usage to reset `freeUsesUsed` and `paidCredits`.
6. Tap Add 10 credits or Add 50 credits to increase backend credits.
7. Tap Simulate Premium On and verify `/v1/me` reports premium state.
8. Tap Simulate Premium Off and verify free/credit usage is active again.
9. Tap Refresh account state to fetch `/v1/me` without changing backend values.

Flutter does not fake account state. The backend remains the source of truth.

## Safety

Never enable these flags in production:

```text
MOCK_AI_ENABLED=true
DEV_TOOLS_ENABLED=true
```

Backend startup fails if either flag is true while `APP_ENV=prod` or `REPLY_ENV=prod`.
The Settings Developer Testing panel is hidden in release builds and when the app is not configured for dev tools.
The dev endpoints require bearer auth, do not call RevenueCat, and return 404/403 when disabled.
