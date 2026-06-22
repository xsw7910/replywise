# Phase 1 Checklist — Static UI

Source of truth: `docs/ReplyWise_development_plan.md`

## Phase goal

Build production-quality static screens and local interactions that communicate the ReplyWise product without invoking backend business APIs.

## Allowed scope

- Reply, Polish, Settings, and static Paywall screens.
- Guidance Library chips, audience/tone controls, input fields, navigation, and fake result cards.
- One light-blue glass visual system using centralized tokens and `BackdropFilter`.
- Existing Phase 0 `/health` display.

## Not allowed yet

- Authentication, protected backend calls, AI generation, real usage enforcement, purchases, RevenueCat SDK behavior, credit sync, or functional entitlement/paywall gating.
- Dark mode, theme switching, floating bubble, keyboard extension, automatic sending, or cloud history.

## Required Flutter work

- Reply UI: incoming message, guidance, audience `auto/preset/custom`, formality, Guidance chips, Generate placeholder, three fake result cards, Copy affordances, Regenerate placeholder, and Explain button placeholder.
- Explain is represented inside Reply and targets a bottom-sheet interaction; never add an Explain route/tab.
- Polish UI: draft, direction `natural/professional/friendly/concise/custom`, custom guidance, Generate placeholder, and fake polished result.
- Settings has no theme selector and contains only planned static settings/status entries.
- Paywall statically shows both “Start 3-day Free Trial” and “Buy Credits” paths with clear trial terms; no purchase execution.
- Guidance chips use the fixed local presets from the plan and fill/append guidance.
- Results prioritize readability; glass blur is limited and input focus remains readable.

## Required backend work

- None beyond preserving Phase 0 `/health`.

## Required files/folders

- Feature presentation files for Reply, Polish, Settings, and Paywall.
- Shared theme skin/tokens and reusable input/button/card widgets where needed.
- Router entry for `/paywall`; bottom navigation remains Reply, Polish, Settings only.

## Data/security notes

- Use fake/local data only. Do not imply purchases or generated content succeeded.
- Do not persist or send message bodies during this phase.

## Acceptance criteria

- Every main entry is clickable and the Reply/Polish purposes are obvious.
- Guidance chips and static controls behave locally.
- Explain remains inside Reply; Paywall exposes both planned paths without real billing.
- The single light-blue glass style is consistent and result text is clearly readable.
- No backend business call occurs except existing `/health`.

## Test commands

```text
cd app && flutter analyze
cd app && flutter test
```

Manual: traverse every route and control at compact and standard Android sizes; verify no overflow and no active purchase/generation behavior.

## Codex review checklist

- [ ] All four static screens and planned local controls exist.
- [ ] Explain is not a route/tab; Guidance chips are local.
- [ ] Paywall is explicitly non-functional and shows both payment paths.
- [ ] Theme tokens are centralized; no theme switching was added.
- [ ] No future-phase API or billing logic was introduced.
- [ ] Analysis/tests pass and main layouts do not overflow.

## Claude Code implementation prompt

```text
Implement only the static Phase 1 UI in docs/PHASE_1_CHECKLIST.md. Use fake
data and local interactions. Preserve /health; do not add auth, AI, usage, or
purchase behavior. Run flutter analyze and flutter test.
```

## Codex review prompt

```text
Review only Phase 1 static UI against docs/PHASE_1_CHECKLIST.md. Check scope,
routes, local interactions, visual tokens, overflow, and absence of future-phase
logic. Return PASS or NEEDS CHANGES with exact files.
```

