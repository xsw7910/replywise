# Phase 5A Checklist — RevenueCat Subscription

Source of truth: `docs/ReplyWise_development_plan.md`

## Phase goal

Complete the annual premium subscription path, including a Google Play 3-day free trial, backend verification, restore, and correct premium consumption behavior.

## Allowed scope

- Google Play subscription, RevenueCat Android configuration, premium entitlement/offering, subscription paywall path, restore, `/v1/entitlement/sync`, and subscription cache.
- Premium model selection after the plan’s quality evaluation.

## Not allowed yet

- Consumable credit products, credit purchase UI, `credit_purchases`, or `/v1/credits/sync`.
- RevenueCat webhooks or other post-MVP enhancements.

## Required Flutter work

- Configure RevenueCat with the Android public SDK key and the stable existing `appUserId`.
- Load offering `default`; purchase annual package and restore purchases.
- Paywall primary CTA says “Start 3-day Free Trial” and clearly states “Free for 3 days, then [price]/year. Cancel anytime.”
- Purchase/restore success calls authenticated `/v1/entitlement/sync`, then refreshes `/v1/me`.
- Client RevenueCat state may update UI immediately, but backend `/v1/me` remains authoritative for generation access.
- Handle empty offerings, configuration failure, purchase cancellation, sync failure, and restore failure without granting access locally.

## Required backend work

- `/v1/entitlement/sync` requires bearer auth, uses token-bound `appUserId`, never creates users, and ignores client premium claims.
- Query RevenueCat using the backend secret key, update `subscription_cache`, and return merged entitlement/usage.
- Active trial counts as premium. Premium consumes no free use or credit and returns `freeUsesLeft: null` everywhere.
- Inactive/expired subscription returns the factual pre-subscription free count and preserved paid-credit balance.
- RevenueCat unavailability uses the planned cached-state/error behavior without falsely granting premium.

## Required files and external configuration

- Google Play product `premium_yearly`, yearly base plan (identifier: `yearly`), and 3-day trial offer.
- RevenueCat project/Android app, entitlement `premium`, offering `default`, and annual package (`$rc_annual`) attached to the entitlement.
- Flutter subscription repository/controller/paywall integration.
- Backend RevenueCat verifier, entitlement route/service, subscription cache persistence, config, and tests.

## Security/billing notes

- Public RevenueCat SDK key is Flutter-only; secret RevenueCat API key is backend-only and never committed.
- Client premium state is never authorization.
- Trial and premium skip consumption; they do not reset `free_uses_used` or alter `paid_credits`.
- Before fixing the production premium model, evaluate at least 20 realistic Chinese/English scenarios for naturalness and guidance adherence.

## Acceptance criteria

- Test subscription starts a trial and backend reports premium immediately after sync.
- Premium/trial generation is not blocked and changes neither free uses nor credits.
- Cancellation during trial becomes free after trial expiry and sync.
- Expiry restores the exact remaining free uses and existing credits.
- Restore works with the stable `appUserId`; trial terms are visible before purchase.
- Forged premium input cannot unlock backend generation.

## Test commands

```text
cd app && flutter analyze
cd app && flutter test
cd backend && python -m pytest
```

Manual license-tester flows: first trial, purchase, cancel/expire, relaunch/sync, restore, offline/configuration failure, and free-balance preservation.

## Codex review checklist

- [ ] Subscription/trial products and entitlement mapping match IDs.
- [ ] Backend verification is authoritative and token-bound.
- [ ] Premium nullable/free/credit semantics are preserved across every response.
- [ ] Restore and failure paths never grant false access or lose prior balance.
- [ ] Trial pricing/cancellation text is explicit.
- [ ] No Phase 5B credit purchase flow was added.
- [ ] Automated and tester flows pass.

## Claude Code implementation prompt

```text
Implement only the subscription path in docs/PHASE_5A_CHECKLIST.md. Keep backend
verification authoritative, preserve free/credit balances, and exclude all
consumable credit purchase work. Run tests and report external setup needed.
```

## Codex review prompt

```text
Review only Phase 5A subscription/trial behavior. Verify client/server trust
boundaries, premium consumption semantics, expiry, restore, trial disclosure,
and absence of credit purchase work. Return PASS or NEEDS CHANGES.
```
