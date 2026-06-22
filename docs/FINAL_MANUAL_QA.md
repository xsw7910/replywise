# Final Manual QA

Source of truth: `docs/ReplyWise_development_plan.md`

Run this checklist on the signed internal-testing build with production-like configuration.

## Installation and layout

- [ ] Fresh install launches without a crash
- [ ] Upgrade from the previous internal build preserves the anonymous user
- [ ] Reply, Polish, Settings, and Paywall render on small and large Android screens
- [ ] Text remains readable with increased system font size
- [ ] Keyboard does not hide primary actions and dismisses on scroll
- [ ] TalkBack labels and focus order are understandable

## Core flows

- [ ] Reply validates empty input, loads, returns results, copies text, and regenerates
- [ ] Polish validates empty input, loads, returns a result, copies text, and runs again
- [ ] Explain loads in the Reply screen and displays meaning, tone, hidden meaning, and suggestions
- [ ] Guidance chips and custom guidance behave as labelled
- [ ] Remaining free uses and credits refresh after successful generation
- [ ] Regeneration warning clearly states that one generation is used

## Failure and recovery

- [ ] Offline startup shows a friendly session status and retry action
- [ ] Reply, Polish, and Explain failures never expose raw server details
- [ ] Retry recovers after connectivity returns
- [ ] Rate-limit and paywall-required messages lead to the correct next action
- [ ] Settings backend status can be refreshed without exposing raw errors

## Billing

- [ ] Paywall loading, unavailable, purchase, cancellation, and error states are clear
- [ ] Premium purchase syncs and enables unlimited generation
- [ ] Restore Premium works after reinstall with the same store account
- [ ] Credit packages load, purchase, reconcile, and grant exactly once
- [ ] Premium generation preserves free uses and credits
- [ ] Non-Premium generation consumes free uses before credits

## Release checks

- [ ] Production HTTPS backend is used
- [ ] Version and app identity match the Play Console release
- [ ] No debug UI, local URLs, secrets, or test purchase text is visible
- [ ] Privacy policy and data safety disclosures are accessible and accurate
- [ ] Crash-free smoke test completed on at least one physical Android device

Record device, Android version, tester, build version, date, failures, and retest result with the release evidence.
