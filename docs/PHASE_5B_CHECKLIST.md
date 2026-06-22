# Phase 5B Checklist — Consumable Credit Packages

Source of truth: `docs/ReplyWise_development_plan.md`

## Phase goal

Sell verified one-time credit packages and grant each store transaction exactly once, including recovery when purchase succeeds but immediate sync does not.

## Allowed scope

- Products `credits_10`, `credits_50`, `credits_100`, paywall credit path, purchase handling, `/v1/credits/sync`, transaction persistence, and automatic reconciliation.

## Not allowed yet

- New subscription tiers, client-declared credit grants, cloud/account features, or webhook-dependent behavior.

## Required Flutter work

- Add the three consumable packages to the existing offering and show a clear “Buy Credits” path beside subscription.
- After purchase success, call authenticated `/v1/credits/sync`, then refresh `/v1/me`.
- Also reconcile on every app startup and every paywall open for MVP purchase-loss recovery.
- Treat sync as idempotent; `grantedThisSync: 0` is a normal result.
- Display separate or combined free/paid balance accurately; premium users still display Premium.
- Restore purchases applies to subscriptions, not consumable credit restoration; authoritative granted balance comes from backend state.

## Required backend work

- `/v1/credits/sync` requires bearer auth and uses token-bound `appUserId`.
- Query RevenueCat-verified non-subscription transactions; never trust client product, amount, or purchase-success claims.
- Map only planned products to grants: `credits_10→10`, `credits_50→50`, `credits_100→100`.
- `credit_purchases.transaction_id` is unique/primary. In one transaction, insert a new verified purchase and increment `usage_summary.paid_credits`; existing transactions are skipped.
- Return current entitlement/usage plus `grantedThisSync`.
- Credit grant occurs even while premium/trial is active. Premium prevents consumption, not grant.

## Required files/folders

- Flutter credit purchase/sync repository and controller integration with paywall/startup.
- Backend credit sync route/service, `credit_purchases` table/index, product/grant configuration, RevenueCat transaction verification, and tests.
- Google Play consumable products and RevenueCat offering packages.

## Data/security notes

- Credit packages are consumable and repeatable; they are not attached to the premium entitlement.
- Transaction IDs enforce exactly-once grant under retries and concurrent sync.
- Credit consumption remains Phase 4 logic: free first, then credits; premium skips both.
- `.env` product mappings and RevenueCat secret remain backend-only and uncommitted.

## Acceptance criteria

- Each test package grants exactly 10/50/100 credits.
- Repeated and concurrent sync never grants a transaction twice.
- Killing the app after purchase but before sync is repaired on next startup.
- Startup/paywall reconciliation safely returns zero when nothing is pending.
- Premium/trial purchases are granted and preserved but not consumed until the user is non-premium.
- With free uses exhausted, generation consumes credits; paywall appears only when both pools are empty.

## Test commands

```text
cd app && flutter analyze
cd app && flutter test
cd backend && python -m pytest
```

Manual license-tester flows: buy each package, repeat purchase, kill before sync, relaunch, reopen paywall, duplicate sync, premium purchase/grant, and post-premium consumption.

## Codex review checklist

- [ ] Product IDs, grant mappings, and consumable configuration match.
- [ ] Every grant is backend-verified and transaction-idempotent.
- [ ] Purchase-loss recovery runs at all three required times.
- [ ] Premium affects consumption only, never verified grant.
- [ ] Subscription restore is not misrepresented as credit restoration.
- [ ] Automated and tester flows pass without duplicate balance.

## Claude Code implementation prompt

```text
Implement only consumable credits from docs/PHASE_5B_CHECKLIST.md. Make backend
verification, transaction-idempotent grant, and crash recovery blocking. Do not
add unrelated billing products or features. Run all listed tests.
```

## Codex review prompt

```text
Review Phase 5B as a money/data-integrity audit. Test duplicate, concurrent,
crash-before-sync, startup/paywall reconciliation, premium grant, and later
consumption paths. Return PASS or NEEDS CHANGES with exact files.
```

