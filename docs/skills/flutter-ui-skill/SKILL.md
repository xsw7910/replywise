---
name: flutter-ui-skill
description: Production-quality Flutter UI rules for ReplyWise — glassmorphism theme, loading/error states, spacing, accessibility.
version: 1.0
---

## Purpose

Ensure every ReplyWise screen is production-ready: correct states, consistent spacing, accessible, and aligned with the single light-blue glassmorphism theme.

## When to use

When building or reviewing any Flutter screen, widget, or visual component.

## Core rules

1. **One theme**: single light-blue glassmorphism style. No dark mode, no theme selector in MVP.
2. **No inline styles**: use `AppTextStyles`, `AppColors`, and `AppTextStyles.*` constants only.
3. **GlassCard** wraps input groups and result sections (`BackdropFilter`, blur, opacity 0.20 idle → 0.45 focused).
4. **Every async action** has three states: loading (spinner replaces icon), result, error — all must be visible somewhere.
5. **Regenerate button** appears only after a result exists; for non-premium users it shows "Regenerating consumes 1 use." beneath it.
6. **Copy** shows a `SnackBar("Copied")`, optional haptic — never auto-sends or switches apps.
7. **Explain** opens as a `showModalBottomSheet`, never a screen or navigation push.

## Implementation rules

- Use `ConsumerStatefulWidget` for screens that own local form state.
- Use `ConsumerWidget` for stateless display widgets that only read providers.
- Wrap all `ListView` padding in `EdgeInsets.fromLTRB(16, 18, 16, 32)`.
- Spacing between sections: `SizedBox(height: 14)` standard, `SizedBox(height: 26)` before result headline.
- Error inline: `_InlineError` widget with `AppColors.error.withAlpha(18)` background — never a dialog for field errors.
- Loading button: replace icon with `SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))`.
- `PAYWALL_REQUIRED` error must show a "View plans" `TextButton` below the error message.
- `maxLength` and `maxLines` on every `LabeledTextField` match backend validation limits.
- `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` on all scrollable screens.

## Common mistakes

- Adding theme toggles, custom fonts, or dark-mode branches — not in scope.
- Showing a dialog for inline field validation errors instead of `_InlineError`.
- Missing loading state on the Regenerate button (must disable and show spinner like the primary button).
- Forgetting the non-premium cost warning under Regenerate.
- Calling `context.push(...)` from inside a repository or controller — routing stays in UI layer.
- Using hardcoded color values instead of `AppColors` constants.

## Review checklist

- [ ] All three states (loading, result, error) are visible in the widget tree.
- [ ] GlassCard used for all input groups and result cards.
- [ ] Spacing constants match style guide (14 / 26 / 12 as appropriate).
- [ ] Regenerate button only appears post-result; non-premium warning present.
- [ ] PAYWALL_REQUIRED shows "View plans" CTA.
- [ ] No hardcoded colors or text styles.
- [ ] No dialog used for inline field validation.
- [ ] flutter analyze reports no issues.

## Acceptance criteria

- `flutter analyze` clean.
- All three states render correctly in manual testing.
- Glassmorphism style consistent with existing Reply screen.
- No regressions in other screens.

## Example Claude Code prompt

```text
Read docs/AI_CONTEXT.md and docs/skills/flutter-ui-skill/SKILL.md.
Add the [feature] screen following the glassmorphism style and loading/error/result state pattern.
```

## Example Codex review prompt

```text
Review [screen].dart against docs/skills/flutter-ui-skill/SKILL.md.
Check all three async states, spacing constants, GlassCard usage,
Regenerate warning, and PAYWALL_REQUIRED CTA. Return PASS or NEEDS CHANGES.
```

## Related documents

- `docs/AI_CONTEXT.md` — glassmorphism decision, Regenerate cost disclosure rule
- `docs/skills/flutter-architecture-skill/SKILL.md` — widget/controller separation
- `docs/ReplyWise_development_plan.md` §4, §19 — screen state fields, theme spec
