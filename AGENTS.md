# AGENTS.md

## Project
- Build **Paint Mountain**, a focused Godot 4.x desktop 3D physics-puzzle game in which a stationary cannon launches paintballs that continuously paint every target surface traversed while in contact across a distant mountain.
- Preserve the planning puzzle: the player chooses yaw, elevation, and power before firing and never steers a projectile in flight.
- Treat the verbatim directive in `docs/source-brief.md` as the baseline product requirement. Explicit later user revisions recorded in that document supersede only the clauses they name; `docs/design-spec.md` and `docs/technical-architecture.md` remain working interpretations, and the effective source brief wins any conflict.
- Check `.agents/Documentation.md` for implemented status before claiming that a planned feature exists.
- Before visual or substantial player-facing work, load `$uiux-gate` and read `.agents/design/DESIGN.md`; use its task map to consult the relevant `docs/visual-direction/*` specifications and production owners.

## Operating Model
- Use Godot 4.x, typed GDScript where practical, the Compatibility renderer, a fixed 60 Hz physics tick, and Windows desktop as the first delivery target.
- Keep the project launchable after each milestone. Run `scripts/verify.ps1` after script, scene, resource, or project-setting changes.
- Do not add production dependencies, plugins, network services, Docker, or asset packs without the user's explicit approval.
- Before broad or cross-module implementation, use the relevant active ExecPlan under `.agents/execplans/` and finish with `$codebase-quality-auditor`.
- Final gameplay handoff requires an exported or production-style build check and separate running-game screenshots listed in `docs/test-checklist.md`.

## Architectural Guardrails
- `StageController` is the sole owner of the stage state machine, shot progression, and clear/failure decisions.
- `PaintSystem` owns the authoritative runtime paint mask used by both terrain visuals and coverage; never maintain a second coverage representation.
- Store projectile, stage, mechanism, and result tuning in typed Resources rather than stage scripts or global constants.
- Keep game rules independent of HUD and human input so replay, tests, and the future in-process AI interface use the same actions and observations.
- Communicate cross-system events through typed signals or narrow interfaces; do not hardcode stage-specific node paths in global scripts.
- Keep the bootstrap scene isolated under `scenes/bootstrap` and `src/bootstrap`; retire it only after a real gameplay entry scene passes the same smoke checks.

## Living Guidance
- This file is project-specific operating guidance.
- Its contents may be added, edited, reorganized, or removed as user requests and project conditions change.
- Keep only durable repo-wide instructions here when they do not need a separate workflow trigger.
- Prefer folder and file names that reveal purpose and function instead of explaining the whole structure in root `AGENTS.md`.
- Do not treat current folder structure, temporary placement decisions, or subtree names as a root-level contract unless the user explicitly wants that contract.

## Preflight
<!-- Fixed section. Keep this block exactly as defined by agent-governor. -->
### General
- Add short, truthful docstrings or inline comments when they materially clarify intent, responsibility, invariants, non-obvious constraints, or future handoff points for humans and agents.
- Prefer append-first updates that preserve prior intent and newly discovered constraints, but rewrite or remove comments when they become stale, redundant, or too long to stay trustworthy.
- If a commented class, function, or code block is deleted or its behavior changes, update or delete the attached comment in the same change.
- If the user's intended outcome is materially ambiguous and the ambiguity could change the implementation, output, or conclusion, ask a concise follow-up question with explicit options before proceeding.
- Do not ask follow-up questions when a reasonable, low-risk default is already clear from the request and local context.
- Prefer responsibility-shaped files and modules over large catch-all scripts; before expanding a large file, identify its owned responsibility, what it should not absorb, and whether local boundaries already cover the change.

### FE
- Prefer a component-driven UI so design and behavior stay consistent.
- Check alignment, typography, spacing, and padding/gap explicitly.
- Check overflow and clipping explicitly; no child element should be visibly cut off or exceed its container at supported desktop/mobile widths.
- Avoid unnecessary explanatory or guideline text.
- Keep non-essential elements visually restrained.

### BE
- Remove obsolete legacy code once the replacement is clearly in place.
- Design for reuse when the boundary is clear.
- Add logging where operational visibility matters, and persist it when the workflow depends on it.

### DB
- Ask before running broad or intensive database reads unless the need is already explicit.

## Project Memory
- Before broad, risky, or multi-file governance work, read the relevant files under `.agents/`.
- Use an ExecPlan only for work that matches the ExecPlan Standard in `.agents/PLANS.md`; do not create one for simple questions, single-note judgments, or small one-file edits.
- Use `.agents/*` for durable project memory, evolving plans, workflow notes, recurring gotchas, and repo-local skills.
- Keep transient discoveries and in-progress status there instead of in root `AGENTS.md`.

## Documentation Lifecycle
- For agent-relevant Markdown that may guide future work, use `$doc-lifecycle-steward` to classify lifecycle `type` and `status`.
- Add lifecycle frontmatter only to agent-relevant `policy`, `spec`, `plan`, `handoff`, `evidence`, or `record` documents.
- Do not frontmatter-stamp protected instruction files such as `AGENTS.md`; audit them and propose minimal changes instead.

## Placement Rules
- Put stable repo-wide guidance in this file.
- Put subtree-specific placement or operating rules in the nearest local `AGENTS.md` only after that subtree has a stable distinct responsibility.
- Put durable supporting memory and evolving notes in `.agents/*`.
- Prefer purpose-revealing naming over root-level structure prose where naming can carry the meaning.
- Create a repo-local skill only when a workflow repeats and needs its own trigger, stop conditions, or artifact contract.
- Do not fill root `AGENTS.md` with directory maps, transient inventories, or guidance that only describes the current layout.
