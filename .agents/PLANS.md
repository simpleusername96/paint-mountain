---
type: policy
status: active
created: 2026-08-02
scope: repository execution planning
---

# ExecPlan Standard

## Purpose

Keep broad Paint Mountain work executable across sessions without turning small changes into process overhead.

## Scope

Use an ExecPlan for cross-system gameplay work, scene/resource schema changes, save/replay format changes, renderer or paint-mask changes, risky cleanup, or changes spanning more than five files. Do not require one for Q&A, documentation corrections, narrow tuning, or small isolated fixes.

## Rules

- Complete read-only discovery before writing a decision-complete plan.
- Resolve product, dependency, ownership, persistence, and validation choices before execution tasks begin.
- Include purpose, verified evidence, locked decisions, scope/non-scope, architecture ownership, ordered tasks, acceptance checks, regression guards, validation commands, contingencies, progress, next steps, and stop conditions.
- Keep only one active ExecPlan under `.agents/execplans/` unless the user explicitly requests separately scoped concurrent work. Treat `Plan.md` as a historical index unless its lifecycle frontmatter explicitly makes it the active plan.
- Mark a completed plan `done`; preserve lasting decisions in the active specs or `Documentation.md`.
- Never use a plan to authorize destructive actions, new dependencies, or scope expansion that still requires user approval.

## Exceptions

- Post-change inspection and testing may remain in an execution plan when they validate the selected implementation rather than choose it.
- Approval gates may remain only for an already-defined action that policy requires the user to approve.
