# ReplyWise Google Play Internal Testing

Source of truth: `docs/ReplyWise_development_plan.md`

This is a release-preparation runbook. It does not upload an artifact or contain credentials.

## Repository readiness

- [x] Production dart-defines are supported by `scripts/build.ps1`.
- [x] Release scripts require `REPLY_ENV=prod`, a real HTTPS backend URL, and a RevenueCat Android public key.
- [x] Main Android manifest declares `INTERNET` and does not enable cleartext traffic.
- [x] Cleartext traffic is enabled only by the debug manifest for local development.
- [x] Release no longer uses the debug signing key.
- [x] Upload-key files and `key.properties` are ignored by Git.
- [x] Existing launcher icons and splash resources are packaged.
- [x] Current internal-test version is `1.0.0+1`; increment `+1` before the next upload.
- [ ] Configure upload signing locally or through protected CI variables.
- [ ] Build and retain the signed AAB plus test evidence.

## Production build

Required public/configuration values:

- `REPLY_BACKEND_BASE_URL=https://<production-host>`
- `REPLY_ENV=prod`
- `REVENUECAT_ANDROID_API_KEY=goog_<public-sdk-key>`
- `REVENUECAT_ENTITLEMENT_ID=premium`

Signing can come from ignored `app/android/key.properties`:

```properties
storeFile=<path-to-upload-keystore>
storePassword=<local-secret>
keyAlias=<upload-key-alias>
keyPassword=<local-secret>
```

Alternatively set `REPLYWISE_UPLOAD_STORE_FILE`, `REPLYWISE_UPLOAD_STORE_PASSWORD`, `REPLYWISE_UPLOAD_KEY_ALIAS`, and `REPLYWISE_UPLOAD_KEY_PASSWORD` in protected CI/local environment variables.

Run:

```powershell
.\scripts\release.ps1 `
  -ReplyBackendBaseUrl "https://<production-host>" `
  -RevenueCatAndroidApiKey "goog_<public-sdk-key>" `
  -RevenueCatEntitlementId "premium"
```

Expected artifact: `app/build/app/outputs/bundle/release/app-release.aab`.

## Google Play Console

- [ ] Create/verify app for package `com.novaaistudio.replywise`.
- [ ] Enable Play App Signing and register the upload certificate.
- [ ] Create the Internal testing release and add release notes.
- [ ] Add internal testers and publish the tester opt-in link.
- [ ] Add license-test accounts for billing tests.
- [ ] Confirm the signed AAB version code is greater than every previous upload.
- [ ] Confirm all required declarations and app access questions are complete.

## RevenueCat and products

- [ ] RevenueCat Android app uses package `com.novaaistudio.replywise`.
- [ ] Google Play service credentials are connected and valid.
- [ ] Entitlement `premium` exists.
- [ ] Offering `default` is active.
- [ ] Subscription `reply_premium_monthly` has an active monthly base plan.
- [ ] The subscription has a 3-day free-trial offer available to eligible testers.
- [ ] `credits_10`, `credits_50`, and `credits_100` are active repeatable consumables.
- [ ] All four products are attached to the expected RevenueCat offering/packages.
- [ ] Backend production environment has the RevenueCat secret key; it is not in Flutter or Git.

## Store listing and assets

- [ ] App name, short description, full description, category, contact details, and support URL are complete.
- [ ] Listing describes Reply, Polish, Explain, five lifetime free uses, Premium trial, restore, and credit packs accurately.
- [ ] Listing does not claim automatic sending, background clipboard monitoring, overlays, or other unimplemented behavior.
- [ ] Phone screenshots show the current Play-delivered UI and avoid private message content.
- [ ] High-resolution icon and feature graphic meet current Play requirements.
- [ ] Launcher icon and splash appearance are checked on representative Android devices.

## Privacy Policy and Data Safety

- [ ] Publish a reachable HTTPS Privacy Policy URL.
- [ ] Explain transmitted message/draft text, AI processing purpose, and default no-body storage policy.
- [ ] Disclose anonymous app/device identifiers, usage records, entitlement/purchase status, and payment handling.
- [ ] Explain deletion/contact procedure and retention of account, usage, and transaction records.
- [ ] Data Safety matches text transmission, identifiers, purchases, app activity/usage, encryption in transit, and deletion handling.
- [ ] Declare that data is not sold.
- [ ] Do not declare microphone collection unless voice capture is present in the submitted build; request only permissions used by that build.
- [ ] Confirm clipboard behavior is user-initiated copy/paste with no background monitoring.

## Internal test matrix

- [ ] Fresh install creates anonymous identity and reaches production `/health` over HTTPS.
- [ ] Reply, Polish, and Explain work through the production backend.
- [ ] Exactly five free Reply/Polish generations succeed; the sixth opens the paywall.
- [ ] Trial terms show three free days, monthly price, and cancellation language before purchase.
- [ ] Trial purchase activates Premium after backend entitlement sync.
- [ ] Premium generations consume neither free uses nor paid credits.
- [ ] Restore purchases works after reinstall/relaunch with the stable app user identity.
- [ ] Cancellation/expiry returns the exact preserved free and paid balances.
- [ ] Each credit package grants exactly 10, 50, or 100 credits.
- [ ] Reopening the app/paywall reconciles a purchase interrupted before immediate sync.
- [ ] Repeated credit sync grants each transaction once only.
- [ ] Non-premium generation consumes free uses before paid credits.
- [ ] Offline, purchase cancellation, empty offering, and verification failure show safe errors without granting access.

## Evidence and release decision

- [ ] Record AAB version, SHA-256, build date, commit, and tester account type.
- [ ] Record production health URL result without storing credentials.
- [ ] Record Play/RevenueCat product screenshots or links in the private release workspace.
- [ ] Record each test-matrix result and any blocking defect.
- [ ] Release owner signs off before expanding beyond Internal testing.

Never commit keystores, passwords, service-account JSON, backend secrets, or real tester credentials.
