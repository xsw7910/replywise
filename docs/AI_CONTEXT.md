# ReplyWise AI Context

Source of truth: `docs/ReplyWise_development_plan.md`

This is developer guidance, not a replacement for the full plan. If documents conflict, follow the newest explicit requirement in the full plan and update these guidance files.

## Project goal

ReplyWise helps non-native English speakers understand messages, express reply intent in their native language, generate natural English replies, and polish English drafts. The first delivery target is an Android MVP suitable for Google Play Internal Testing.

## MVP scope

- Reply: generate Formal, Casual, and Concise versions plus a native-language explanation.
- Polish: improve an English draft without changing its meaning or inventing facts.
- Explain: clarify meaning, tone, hidden meaning, and suggested English replies inside Reply.
- Guidance input, audience controls, voice input, copy flow, and local guidance chips.
- Anonymous authentication, backend-controlled usage, subscription, and consumable credits.
- FastAPI backend deployed separately; message bodies are not stored by default.

## Current architecture and stack

- Flutter 3.x, Riverpod, `go_router`, Dio, and Material 3.
- Feature-oriented Flutter folders with `core/` for configuration, networking, storage, theme, and shared widgets.
- FastAPI with Pydantic, async HTTP, SQLite for local development, and PostgreSQL with asyncpg in production.
- RevenueCat and Google Play for subscriptions and consumable credit packages.
- Oracle VM, Docker Compose, Caddy, and HTTPS for production hosting.
- Build-time Flutter configuration through `--dart-define`; backend secrets through environment variables.

## Naming and language rules

- Use `guidance`, never `instruction`, in APIs, state, prompts, and UI concepts.
- Explain belongs inside Reply and opens as a bottom sheet; it is not a screen or navigation tab.
- MVP generated output is English; `outputLang` is fixed to `en`.
- Typed guidance may be any language and is understood automatically; do not require a language selection.
- Voice guidance defaults to Auto Detect, with a manual language fallback when needed.
- Reply `why`, Polish `changes`, and Explain prose follow the App interface language.
- Do not add `lengthPreference`; the three Reply variants already cover length.

## Architecture and security rules

- Flutter never calls a model provider directly. Model API keys exist only on the backend.
- Except `/health` and anonymous authentication, protected `/v1/*` APIs derive identity from a bearer token.
- Never trust client identity headers, premium flags, purchase claims, or credit amounts.
- `appUserId` is the primary anonymous-user anchor; `deviceId` is supporting context, not a credential.
- A single auth service owns token lifecycle. Refresh must be single-flight and bounded.
- Use async backend I/O. Never hold a database transaction or connection during an LLM call.
- Do not store incoming text, guidance, drafts, polished text, or generated replies by default.
- Production services, database, environment, RevenueCat credentials, and Caddy routing remain isolated from other apps.

## Billing rules summary

- Backend state is authoritative for premium, free usage, and paid credits.
- Access order is premium first; otherwise free uses first, then paid credits; otherwise paywall.
- Free lifetime limit is 5. `free_uses_used` is factual and is never reset during premium.
- Premium users consume neither free uses nor paid credits; `freeUsesLeft` is `null` for premium.
- A successful non-premium generation consumes one unit; `source` identifies `free` or `credit`.
- Generation uses backend-computed request hashes, idempotency, atomic pre-deduction, and source-aware rollback.
- Credit grants are independent of consumption: premium blocks credit consumption, never verified credit grant.
- RevenueCat state and consumable transactions must be verified by the backend.

## Product decisions

- Regenerate consumes one unit for non-premium users and must be disclosed before use.
- Explain consumes one usage unit (free use or paid credit) per successful
  generation, exactly like Reply and Polish, and additionally keeps its own
  backend daily rate limit as an abuse guard.
- Copy never auto-sends or automatically switches back to another app.
- The first UI has one light-blue glass style; no theme selector or dark theme.
- The paywall presents both a 3-day subscription trial and one-time credit packages.

## Do not implement early

- Do not pull authentication, AI, usage, RevenueCat, credits, or release work into an earlier phase.
- Do not add email login, cloud history, cross-device history, floating bubbles, keyboard extensions, or custom guidance libraries to the MVP phases.
- Do not add multiple themes, dark mode, automatic sending, background clipboard monitoring, or unsupported store claims.
- Structural placeholders are allowed only where the current phase checklist calls for them; inactive future business logic is not.

