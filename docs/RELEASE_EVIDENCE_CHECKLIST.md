# Release Evidence Checklist

Source of truth: `docs/ReplyWise_development_plan.md`

Record evidence for the exact build submitted to Google Play. Do not place secrets in this file.

## Build identity

- [ ] Release commit and branch recorded
- [ ] App version name and version code recorded
- [ ] Signed AAB path, size, and SHA-256 recorded
- [ ] Build date and operator recorded

## Automated verification

- [ ] `scripts/test.ps1` passes
- [ ] `flutter analyze` passes
- [ ] Flutter tests pass
- [ ] Backend pytest passes with no required test skipped
- [ ] `scripts/release.ps1` completes with production parameters

## Production configuration

- [ ] `REPLY_ENV=prod`
- [ ] HTTPS production `REPLY_BACKEND_BASE_URL` verified
- [ ] RevenueCat Android API key supplied outside source control
- [ ] RevenueCat entitlement ID matches the dashboard
- [ ] Production JWT secret and server pepper supplied securely
- [ ] Release manifest does not allow global cleartext traffic

## Backend deployment (see `docs/ORACLE_VM_BACKEND_DEPLOYMENT.md`)

- [ ] Backend `DATABASE_URL` uses PostgreSQL + asyncpg (production rejects SQLite)
- [ ] `docker compose run --rm api alembic upgrade head` applied — production does **not** auto-create tables
- [ ] `docker compose run --rm api alembic current` reports the expected head revision
- [ ] `REVENUECAT_WEBHOOK_SECRET` set and the RevenueCat webhook points to `…/v1/webhooks/revenuecat` with the matching Authorization value

## Billing and Play Console

- [ ] Premium subscription and trial are active and match paywall copy
- [ ] Credit products `credits_10`, `credits_50`, and `credits_100` are active
- [ ] RevenueCat offerings and Google Play products are linked
- [ ] Licensed internal tester completes subscription purchase and restore
- [ ] Licensed internal tester completes each credit purchase and reconciliation

## Product and policy

- [ ] `docs/FINAL_MANUAL_QA.md` completed on the release build
- [ ] Store listing, icon, screenshots, and contact details reviewed
- [ ] Privacy policy URL is public and correct
- [ ] Data safety answers match actual app behavior
- [ ] Internal testing country/device availability reviewed
- [ ] Release owner gives final approval

Developer guidance only. The full development plan remains the source of truth.
