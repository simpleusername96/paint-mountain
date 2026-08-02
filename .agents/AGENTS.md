# .agents/AGENTS.md

## How We Work Here
- This folder is the unified repo-local agent environment for durable project memory, evolving plans, and reusable workflow notes.
- For broad, risky, or multi-file work, read `Prompt.md`, `Documentation.md`, and the active `Plan.md` before implementation.
- Create or replace an ExecPlan only when the work matches `PLANS.md`; simple questions and small one-file edits do not need one.
- Keep diffs scoped, update implementation status truthfully, and record exact validation evidence.
- Treat root `AGENTS.md` as the stable repo-wide operating contract.

## Boundaries
- Product behavior belongs in `docs/design-spec.md`; technical ownership belongs in `docs/technical-architecture.md`.
- `Prompt.md` is a compact interpretation of the originating brief, not a second competing product specification.
- `Documentation.md` records implemented reality and known risks; it must not claim planned work as complete.
- Repo-local skills belong under `.agents/skills/` only after a workflow has repeated and needs its own trigger or artifact contract.
