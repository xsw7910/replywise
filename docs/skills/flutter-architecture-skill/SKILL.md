---
name: flutter-architecture-skill
description: Riverpod provider structure, controller/repository separation, DTO/domain models, AppConfig, and go_router rules for ReplyWise.
version: 1.0
---

## Purpose

Keep Flutter code organized in the feature-oriented folder structure with clean separation of concerns: UI reads state, controllers orchestrate, repositories call the network, domain models carry business logic.

## When to use

When building or reviewing Flutter features, providers, routing, or configuration.

## Core rules

1. **No network calls in widgets.** Widgets read providers and call controller methods only.
2. **Controllers** orchestrate: validate → call repository → update state → trigger side effects (e.g., usage refresh). They do not build UI.
3. **Repositories** call `ApiClient` and parse DTOs into domain models. One repository per backend resource group.
4. **Domain models** are immutable, plain Dart classes. They do not know about Dio or JSON.
5. **DTOs** live in `data/` alongside the repository. Domain models live in `domain/`.
6. **AppConfig** is the only source of `--dart-define` values. Never call `String.fromEnvironment` outside `AppConfig`.
7. **Secrets never in Flutter.** `AppConfig` carries only public build-time values (base URL, RevenueCat public key, env flag). JWT tokens are in `flutter_secure_storage`, never in plain shared_preferences.
8. **go_router** owns all navigation. Named routes live in `AppRoutes` constants. Never push raw strings from widgets.

## Implementation rules

- Feature folder layout: `features/<name>/application/`, `data/`, `domain/`, `presentation/`.
- `core/` contains: `config/app_config.dart`, `network/api_client.dart`, `network/api_error.dart`, `storage/`, `theme/`, `widgets/`.
- Providers generated with `@riverpod` annotation (`riverpod_annotation`). Run `build_runner` after adding providers.
- `@Riverpod(keepAlive: true)` only for app-lifetime singletons (`tokenStorage`, `apiClient`). Feature providers use auto-dispose (default).
- Controller extends `_$ControllerName` (code-gen). State is an immutable value class. State transitions copy previous state to preserve `result` across errors.
- `usageControllerProvider.notifier.refresh()` called by generation controllers after each success — never skipped on error.
- Auth interceptor handles 401 globally: refresh once, then re-issue anonymous if refresh fails. Single-flight with a `Completer` to prevent refresh storms.
- `X-Idempotency-Key` (UUID v4) is generated per new generation request inside the repository, not the controller or widget.
- `freeUsesLeft` typed as `int?` in `EntitlementState` — never assume non-null.

## Common mistakes

- Calling `ApiClient.post()` directly in a widget or controller — goes in the repository.
- Keeping `result` as `null` when an error occurs (loses the previous result on retry) — copy `state.result` into the error state.
- Using `String.fromEnvironment` outside `AppConfig`.
- Storing JWT in `SharedPreferences` instead of `flutter_secure_storage`.
- Pushing a raw route string (`context.push('/paywall')`) instead of using `AppRoutes.paywall`.
- Forgetting `addTearDown(container.dispose)` in provider unit tests.

## Review checklist

- [ ] No `ApiClient`/`Dio` usage inside widgets or controllers.
- [ ] Controller state preserves `result` when emitting an error state.
- [ ] `usageControllerProvider.refresh()` called after successful generation.
- [ ] `AppConfig` used for all environment values.
- [ ] JWT stored in `flutter_secure_storage`.
- [ ] All navigation uses `AppRoutes` constants.
- [ ] `freeUsesLeft` is `int?` throughout (never assumed non-null).
- [ ] `flutter analyze` clean; generated files up to date.

## Acceptance criteria

- `flutter analyze` reports no issues.
- `flutter test` passes.
- No API calls in widgets or controllers (Grep for `dio` / `client.post` outside `data/`).

## Example Claude Code prompt

```text
Read docs/AI_CONTEXT.md and docs/skills/flutter-architecture-skill/SKILL.md.
Implement [feature] following the controller/repository/domain separation.
No network calls in widgets. Preserve state.result on error.
```

## Example Codex review prompt

```text
Review [feature] against docs/skills/flutter-architecture-skill/SKILL.md.
Check controller/repo separation, state preservation on error, AppConfig usage,
secure token storage, and routing. Return PASS or NEEDS CHANGES.
```

## Related documents

- `docs/AI_CONTEXT.md` §architecture — folder layout, security rules
- `docs/skills/flutter-ui-skill/SKILL.md` — widget/state rules
- `docs/ReplyWise_development_plan.md` §1, §2, §3.7 — stack choices, AppConfig, auth flow
