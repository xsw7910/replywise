---
name: google-play-release-skill
description: Safe ReplyWise Android release preparation for Google Play Internal Testing.
version: 1.0
---

## Purpose

Prevent invalid, insecure, or misleading internal-test releases.

## Core rules

1. Release builds use `REPLY_ENV=prod` and a real HTTPS backend URL.
2. Flutter receives only the public RevenueCat Android SDK key. Backend and signing secrets never enter dart-defines or version control.
3. Release must use a stable upload key or Play App Signing workflow, never the debug signing key.
4. Cleartext HTTP may be enabled in the debug manifest only. Main/release manifests must not enable it globally.
5. Every Play upload increments the version code.
6. Product IDs must match exactly: `premium_yearly` (base plan `yearly`), `credits_10`, `credits_50`, `credits_100`; entitlement `premium`; offering `default`; package `$rc_annual`.
7. Trial disclosure states the free period, subsequent annual price, and cancellation terms.
8. Store listing, Privacy Policy, and Data Safety must describe actual behavior only.
9. Internal and license testers verify free usage, subscription/trial/restore, credits, expiry, and duplicate-sync behavior from the Play-delivered build.
10. Release helpers build and report artifacts only; they never upload, commit, or push.

## Review checklist

- [ ] Production dart-defines are validated and contain no placeholders.
- [ ] Upload signing is externally configured and ignored by Git.
- [ ] Main/release manifests do not allow cleartext traffic.
- [ ] Only required Android permissions are declared.
- [ ] No secrets, debug endpoints, or dev URLs ship.
- [ ] Play and RevenueCat identifiers align.
- [ ] Listing, screenshots, privacy disclosures, and Data Safety match the app.
- [ ] Internal-test evidence and purchase results are recorded.

## Required commands

```text
scripts/test.ps1
scripts/release.ps1 <production parameters>
```

Never upload automatically. Stop if signing or production configuration is missing.
