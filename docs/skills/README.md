---
# ReplyWise AI Skills

## What skills are

Skill documents are concise, reusable rule sets for a single technical domain (UI, backend, billing, etc.). Each SKILL.md covers one domain and is phase-independent — its rules apply across all phases.

## How they differ from other documents

| Document | Purpose | When to read |
|---|---|---|
| `docs/AI_CONTEXT.md` | Project goal, stack, naming rules, product decisions | Every session |
| `docs/AI_WORKFLOW.md` | Development loop, roles, commit checklist | Every session |
| `docs/PHASE_<N>_CHECKLIST.md` | Scope, acceptance criteria, test commands for one phase | Current phase only |
| `docs/ReplyWise_development_plan.md` | Full plan, architecture, API contracts, data models | Ambiguity resolution |
| `docs/skills/*.md` | Domain rules reusable across phases | Before implementing or reviewing that domain |

Skills do **not** replace checklists. Checklists define what to build; skills define how to build it correctly.

## When to use skills

- **Before implementing**: load the relevant skill(s) to apply consistent rules without re-deriving them from the full plan.
- **Before reviewing**: load the relevant skill(s) to know what to check.
- **In Claude prompts**: cite the skill file path to give Claude focused domain guidance without loading the entire plan.

## When not to use skills

- Do not load skills instead of the current phase checklist — checklist scope takes precedence.
- Do not use skills to justify implementing out-of-scope features.
- If a skill conflicts with the full plan or a checklist, the checklist wins. Update the skill.

## Available skills

| Skill | Domain |
|---|---|
| [flutter-ui-skill](flutter-ui-skill/SKILL.md) | Production UI, glassmorphism, loading/error states, accessibility |
| [flutter-architecture-skill](flutter-architecture-skill/SKILL.md) | Riverpod, controller/repo separation, routing, AppConfig |
| [fastapi-backend-skill](fastapi-backend-skill/SKILL.md) | Routers, services, schemas, models, dependencies, error handling |
| [api-contract-skill](api-contract-skill/SKILL.md) | camelCase JSON, error codes, DTO alignment, backward compatibility |
| [billing-usage-skill](billing-usage-skill/SKILL.md) | Free uses, credits, idempotency, rollback, rate limiting |
| [testing-review-skill](testing-review-skill/SKILL.md) | Unit, controller, API, concurrency tests; review classification |
| [security-skill](security-skill/SKILL.md) | JWT, auth, authorization, secrets, no client-side trust |

## Example Claude prompt

```text
Read docs/AI_CONTEXT.md, docs/PHASE_4_CHECKLIST.md,
and docs/skills/billing-usage-skill/SKILL.md.
Implement only Phase 4 billing fixes.
```
