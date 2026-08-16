---
type: evidence
status: active
created: 2026-08-14
source: local repository inspection at review baseline 377d71398fe526043ad0158328bbe0bac04abd2e
topic: source map for external review
related:
  - README.md
  - current-state.md
---

# Source Map

## Purpose

Direct ChatGPT Pro to the smallest useful set of current, historical, and
implemented sources without copying the repository into the handoff folder.

## Sources

### Read first

1. `docs/source-brief.md`: verbatim product baseline and later user revisions.
2. `docs/handoffs/special-ball-color-system-chatgpt-pro-2026-08-14/idea-history.md`:
   chronological attribution and proposal status.
3. `project-specs/paint-mountain-difficulty-progression/PRD.md`: neutral draft
   of retained requirements, not an approved implementation spec.
4. `project-specs/paint-mountain-difficulty-progression/OPEN_QUESTIONS.md`:
   unresolved product decisions.
5. `.agents/Documentation.md`: implemented-state record.
6. `docs/design-spec.md` and `docs/technical-architecture.md`: wider gameplay and
   ownership contracts.

### Implemented flow

- `src/stage/stage_controller.gd`: stage state, shot progression, Retry, and
  clear/failure owner.
- `src/cannon/cannon_controller.gd`: launch boundary and current basic-ball data.
- `src/projectile/projectile_manager.gd`: projectile creation and residency.
- `src/projectile/paint_projectile.gd`: physics, contacts, and continuous paint.
- `src/paint/paint_system.gd`: one authoritative paint mask and coverage.
- `src/stage/stage_data.gd`: typed stage configuration.
- `src/mechanisms/` and `src/stage_generation/mechanism_*`: current glyph
  behavior and generated placement pipeline.
- `resources/stages/catalog.tres`: active generated-stage materialization.
- `src/ui/hud_controller.gd` and `scenes/ui/hud/`: current gameplay UI owners.

### Relevant tests

- `tests/phase3_paint_test.gd` and `tests/phase3_projectile_paint_test.gd`:
  paint-mask and projectile-paint contracts.
- `tests/paint_queue_determinism_test.gd`: current paint-operation ordering; it
  is not a future ball-queue test.
- `tests/projectile_contact_test.gd`, `tests/projectile_settling_test.gd`, and
  `tests/projectile_family_capacity_test.gd`: behavior boundaries relevant to
  Burst, rebound, and Split concepts.
- `tests/prediction_projectile_parity_test.gd` and
  `tests/prediction_scheduler_test.gd`: prediction/runtime parity constraints.
- `tests/phase5_mechanism_test.gd` and `tests/mechanism_placement_test.gd`:
  responsibilities affected by any glyph transformation or removal.
- `tests/fixed_mountain_catalog_test.gd`: generated catalog integrity.
- `tests/phase8_hud_truth_test.gd`: HUD truth and ownership boundaries.

### Historical design evidence

- `.agents/execplans/2026-08-13-queued-ball-paint-ownership.md`: superseded
  detailed interpretation. Consult for discovered integration reach only.
- `project-specs/paint-mountain-difficulty-progression/DECISIONS.md`: superseded
  assistant selection and alternatives.
- `.agents/research/paint-mountain-difficulty-progression/RESEARCH.md`: archived
  analogy and local evidence.
- `.agents/evidence/concepts/queued-ball-ui-2026-08-14/*.png`: superseded blue/orange UI
  exploration.

### Recent commits

- `377d713` `docs: visualize queued ball UI flow`
- `e1f5491` `docs: plan queued ball difficulty system`
- `dcd88b7` `docs: replace difficulty progression concepts`
- `51bb11a` `docs: detail difficulty progression blueprint`
- `9eb2237` `docs: plan contrastive difficulty ladder`

## Findings

- The intended future rule is in discussion; current code still implements the
  basic-ball and terrain-glyph game.
- The proposed change crosses gameplay, prediction, paint, stage data, catalog,
  persistence, observation, UI, localization, effects, and tests.
- The handoff contains no secrets, binaries, save data, or copied source files.

## Limitations

- Ignore `.godot/`, exported builds, local user saves, environment files, and
  unrelated generated or cached artifacts.
- Generated catalog files are large. Inspect their schema owners before reading
  all materialized stage resources.
- Remote `master` is the review target; confirm the handoff commit is present
  before analysis.
