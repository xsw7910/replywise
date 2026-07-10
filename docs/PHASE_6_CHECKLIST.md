# Phase 6 Checklist — Google Play Internal Testing

Source of truth: `docs/ReplyWise_development_plan.md`

## Phase goal

Produce and distribute a correctly configured Android App Bundle through Google Play Internal Testing and verify the complete MVP purchase and usage flow.

## Allowed scope

- Release configuration/build, app icon and splash, store listing assets/text, privacy policy, Data Safety, RevenueCat production checks, tester setup, and end-to-end testing.
- Release-blocking fixes only; no new product features.

## Not allowed yet

- Floating bubble, keyboard extension, background message/clipboard monitoring, automatic sending, unsupported store claims, or large UI/architecture changes.

## Required Flutter/release work

- Build release AAB with production `REPLY_BACKEND_BASE_URL`, `REPLY_ENV=prod`, RevenueCat Android public key, and entitlement ID.
- Confirm production backend is HTTPS and release does not enable global cleartext traffic.
- Configure production package/signing/version, icon, splash, microphone/clipboard permissions, and only required Android permissions.
- Verify release build contains no model keys, backend secrets, debug endpoints, verbose diagnostics, or dev URLs.

## Required backend/external work

- Production backend health is reachable over HTTPS and uses isolated production environment/credentials.
- Google Play app, internal track, testers, license testers, subscription/base plan/trial, consumables, and active products are configured.
- RevenueCat Android app, Google credentials, entitlement, offering, subscription, and consumables match production IDs.
- Store listing accurately describes AI replies, Polish, voice guidance, copy, three free uses, trial subscription, and credit packs.
- Privacy policy covers collected data, purpose, AI processing, body-retention policy, payments, and deletion contact.
- Data Safety discloses text transmission, identifiers, purchase status, usage, microphone purpose, clipboard behavior, no data sale, and default no-body storage.

## Required files/folders

- Android release/signing configuration and generated AAB.
- Store listing copy/assets/screenshots, privacy-policy location, and release checklist/evidence as maintained by the project.
- No credentials or signing secrets committed to source control.

## Security/billing notes

- Flutter uses only public RevenueCat SDK key; backend secrets remain server-side.
- Store copy must not claim automatic reading/sending, background clipboard monitoring, or unimplemented overlays.
- Trial text must show free period, subsequent annual price, and cancellation terms.

## Acceptance criteria

- Internal testers can install the Play-delivered build.
- Production `/health`, anonymous auth, Reply, Polish, Explain, free-five usage, paywall, trial subscription, restore, and all credit packages work end to end.
- Repeated credit sync does not duplicate grants; premium bypasses consumption; cancellation/expiry returns correct balances.
- Listing, screenshots, privacy policy, and Data Safety match actual behavior.
- No obvious Play review or secret-exposure risk remains.

## Test commands

```text
cd app && flutter analyze
cd app && flutter test
cd backend && python -m pytest
cd app && flutter build appbundle --release <production dart-defines>
```

Run the plan’s full Android manual checklist using Play internal and license-test accounts, not only a locally installed APK.

## Codex review checklist

- [ ] AAB uses production dart-defines, HTTPS, signing, package, and version.
- [ ] No secret/debug/dev configuration ships.
- [ ] Play and RevenueCat product IDs/entitlement/offering align.
- [ ] Listing, privacy, Data Safety, permissions, and screenshots match behavior.
- [ ] End-to-end free, subscription/trial/restore, and credit flows pass from Play build.
- [ ] No large new feature was introduced during release stabilization.

## Claude Code implementation prompt

```text
Prepare only the Phase 6 Internal Testing release described in
docs/PHASE_6_CHECKLIST.md. Make configuration, disclosure, and end-to-end
release verification the focus. Do not add product features or commit secrets.
```

## Codex review prompt

```text
Review Phase 6 as a release audit. Verify the production AAB configuration,
secret/debug exclusion, Play/RevenueCat alignment, disclosures, and tester
evidence. Return PASS or NEEDS CHANGES with release blockers and exact files.
```

