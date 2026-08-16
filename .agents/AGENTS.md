# .agents/AGENTS.md

## How We Work Here
- This folder is the unified repo-local agent environment for durable project memory, evolving plans, and reusable workflow notes.
- For broad, risky, or multi-file work, read `Prompt.md`, `Documentation.md`, and the relevant active ExecPlan under `execplans/` before implementation.
- Create or replace an ExecPlan only when the work matches `PLANS.md`; simple questions and small one-file edits do not need one.
- Keep diffs scoped, update implementation status truthfully, and record exact validation evidence.
- Keep accepted project knowledge in `../docs/` or its established specification
  owner. Store reusable advisory synthesis in `research/` and retained proof in
  `evidence/`; neither location creates product authority.
- Link research and evidence from each consuming ExecPlan instead of copying
  findings or raw artifacts into plans, design context, or project docs.
- Treat root `AGENTS.md` as the stable repo-wide operating contract.

## Boundaries
- The effective `../docs/source-brief.md` owns product requirements; `../docs/design-spec.md` is its working interpretation, and `../docs/technical-architecture.md` owns technical ownership.
- `design/DESIGN.md` is the single agent-facing design entry; its sibling documents hold detailed visual guidance, while runtime design resources remain in their production-owned locations.
- `Prompt.md` is a compact interpretation of the originating brief, not a second competing product specification.
- `Documentation.md` records implemented reality and known risks; it must not claim planned work as complete.
- `research/` contains concise reusable synthesis, never raw search dumps;
  `evidence/` contains justified captures, logs, measurements, and audit proof.
- Repo-local skills belong under `.agents/skills/` only after a workflow has repeated and needs its own trigger or artifact contract.
